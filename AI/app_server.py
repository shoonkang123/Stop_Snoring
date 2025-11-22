from fastapi import FastAPI
from pydantic import BaseModel
import lightgbm as lgb
import numpy as np
import pandas as pd
import torch
import firebase_admin
from firebase_admin import credentials, firestore
from AI.model.Personalize_freeze import train_transferModel, transferModel
from datetime import datetime, timezone
import os
from pathlib import Path

# ==========================
# Firebase / Firestore 설정
# ==========================
cred = credentials.Certificate(
    r"C:\git_test_alarm\Stop_Snoring\firebase\pasnallized-alarm-service-firebase-adminsdk-fbsvc-c001641e27.json"
)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ==========================
# FastAPI / Device / 모델 경로
# ==========================
app = FastAPI()

device = "cuda" if torch.cuda.is_available() else "cpu"

# LightGBM 모델
model_lightgbm = lgb.Booster(model_file="AI/weight_pt/lightGBM_real_alarm_model.txt")

# LSTM 기본(사전학습) 가중치 & 개인 가중치 디렉토리
BASE_LSTM_PATH = "AI/weight_pt/pretrained_model_full.pt"
PERSONAL_LSTM_DIR = "AI/weight_pt/personal"
os.makedirs(PERSONAL_LSTM_DIR, exist_ok=True)

# ==========================
# Pydantic 입력 스키마
# ==========================
class PredictInput(BaseModel):
    user_id: str
    Bed_sin: float
    Bed_cos: float
    Wake_sin: float
    Wake_cos: float
    Sleep_duration: float
    Sleep_date_sin: float
    Sleep_date_cos: float
    Wake_date_sin: float
    Wake_date_cos: float
    Weekday: int
    Awakenings: int
    Irregular_flag: int
    Alarm_success_rate: float


class UserIdInput(BaseModel):
    user_id: str


# ==========================
# 최근 30개 수면 로그 DataFrame으로 가져오기
# ==========================
def get_last_30_sleep_logs_df(user_id: str) -> pd.DataFrame | None:
    docs = (
        db.collection("users_kim")
        .document(user_id)
        .collection("Sleep_data")
        .stream()
    )

    items = []
    for doc in docs:
        doc_id = doc.id  # 예: "2025-11-23_13-45"
        data = doc.to_dict()
        items.append((doc_id, data))

    if len(items) < 30:
        print(f"[get_last_30_sleep_logs_df] {user_id}: docs={len(items)} < 30 → None")
        return None

    # doc_id(YYYY-MM-DD_HH-MM) 기준 정렬 후 마지막 30개 사용
    items.sort(key=lambda x: x[0])
    last_30 = items[-30:]
    rows = [data for _, data in last_30]

    df = pd.DataFrame(rows)
    print(f"[get_last_30_sleep_logs_df] {user_id}: df.shape={df.shape}")
    return df


# ==========================
# 유저별 개인 LSTM 학습 함수
# ==========================
def train_personal_model_for_user(user_id: str) -> bool:
    print(f"\n[train_personal_model_for_user] user_id={user_id}")
    df = get_last_30_sleep_logs_df(user_id)
    if df is None:
        print(f"[train_personal_model_for_user] {user_id}: 데이터 30개 미만 → 스킵")
        return False

    # 학습에 꼭 필요한 컬럼들
    required_cols = [
        "Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos", "Weekday",
        "Sleep_duration", "Irregular_flag", "Awakenings",
        "Sleep_date_sin", "Sleep_date_cos", "Wake_date_sin", "Wake_date_cos",
        "strength", "snooze_count",
    ]
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        print(f"[train_personal_model_for_user] {user_id}: 누락 컬럼 {missing} → 학습 불가")
        return False

    # 여기서 실제 전이학습 + 개인 가중치 저장
    model_path = train_transferModel(df, user_id)
    ok = os.path.exists(model_path)
    print(f"[train_personal_model_for_user] model_path={model_path}, exists={ok}")
    return ok


# ==========================
# 유저 개인 LSTM 모델 로드
# ==========================
def build_lstm_for_user(user_id: str) -> transferModel:
    model = transferModel().to(device)

    personal_path = Path(PERSONAL_LSTM_DIR) / f"personalized_{user_id}.pt"
    if personal_path.exists():
        state = torch.load(personal_path, map_location=device)
        print(f"[build_lstm_for_user] {user_id}: 개인 모델 로드 → {personal_path}")
    else:
        state = torch.load(BASE_LSTM_PATH, map_location=device)
        print(f"[build_lstm_for_user] {user_id}: 개인 모델 없음 → 기본 모델 사용")

    model.load_state_dict(state)
    model.eval()
    return model


# ==========================
# (옵션) 수동으로 개인 학습 트리거하는 API
# ==========================
@app.post("/train-personal-model")
def train_personal(payload: UserIdInput):
    try:
        ok = train_personal_model_for_user(payload.user_id)
        if not ok:
            return {"error": "데이터가 부족하거나 필요한 컬럼이 없습니다."}
        return {"message": "Training completed successfully"}
    except Exception as e:
        return {"error": str(e)}


# ==========================
# 알람 강도 예측 API
# ==========================
@app.post("/Predict")
def predict_alarm(input: PredictInput):
    user_id = input.user_id
    print("\n[Predict] ================================")
    print(f"[Predict] user_id    = {user_id}")

    # 1) 수면 로그 개수 확인
    logs_ref = (
        db.collection("users_kim")
        .document(user_id)
        .collection("Sleep_data")
        .get()
    )
    total_logs = len(logs_ref)
    print(f"[Predict] total_logs = {total_logs}")

    model_used = ""
    strength = 0

    # 2) 개인 모델 파일 존재 여부
    personal_path = Path(PERSONAL_LSTM_DIR) / f"personalized_{user_id}.pt"
    has_personal = personal_path.exists()
    print(f"[Predict] has_personal = {has_personal}")

    # 3) ★ 30, 60, 90... 개가 될 때마다 재학습
    should_train = (total_logs >= 30) and (total_logs % 30 == 0)
    print(f"[Predict] should_train = {should_train}")
    if should_train:
        print("[Predict] → train_personal_model_for_user 호출")
        ok = train_personal_model_for_user(user_id)
        print(f"[Predict] train ok?   = {ok}")
        if ok:
            has_personal = True  # 방금 학습 성공하면 개인 모델 존재

    # 4) 개인 모델 있으면 LSTM 사용, 아니면 LightGBM 사용
    use_lstm = has_personal
    print(f"[Predict] use_lstm   = {use_lstm}")

    if not use_lstm:
        # ==========================
        # LightGBM 예측
        # ==========================
        lgb_features = np.array([
            input.Bed_sin,
            input.Bed_cos,
            input.Wake_sin,
            input.Wake_cos,
            input.Sleep_duration,
            input.Awakenings,
            input.Irregular_flag,
        ]).reshape(1, -1)

        probs = model_lightgbm.predict(lgb_features)[0]
        lgb_pred = int(np.argmax(probs) + 1)

        model_used = "LightGBM"
        strength = lgb_pred

    else:
        # ==========================
        # LSTM 예측 (개인 모델)
        # ==========================
        lstm_features = np.array([
            input.Bed_sin,
            input.Bed_cos,
            input.Wake_sin,
            input.Wake_cos,
            input.Weekday,
            input.Sleep_duration,
            input.Irregular_flag,
            input.Awakenings,
            input.Sleep_date_sin,
            input.Sleep_date_cos,
            input.Wake_date_sin,
            input.Wake_date_cos,
        ], dtype=np.float32).reshape(1, -1)

        input_tensor = torch.tensor(lstm_features).unsqueeze(0).to(device)

        model_lstm = build_lstm_for_user(user_id)

        with torch.no_grad():
            model_lstm.eval()
            output = model_lstm(input_tensor)   # shape: [1, seq_len, 4]
            output = output.squeeze(0)          # [seq_len, 4] 또는 [1, 4]
            # 개인 fine-tune은 seq_len=30 기준이라면 여기서 마지막 타임스텝 사용
            if output.ndim == 2:
                output_last = output[-1, :].unsqueeze(0)  # [1, 4]
            else:
                output_last = output.unsqueeze(0)         # [1, 4]

            probs = torch.softmax(output_last, dim=1)
            lstm_pred = torch.argmax(probs, dim=1).item() + 1  # 1~4

            # 최근 7일 성공률 피처로 보정
            if input.Alarm_success_rate < 0.5:
                lstm_pred = min(lstm_pred + 1, 4)

        model_used = "LSTM"
        strength = lstm_pred

    # 5) 예측 결과 Firestore에 저장
    date_key = datetime.now(timezone.utc).strftime("%Y-%m-%d_%H-%M")

    doc_data = {
        "user_id": input.user_id,
        "Bed_sin": input.Bed_sin,
        "Bed_cos": input.Bed_cos,
        "Wake_sin": input.Wake_sin,
        "Wake_cos": input.Wake_cos,
        "Sleep_duration": input.Sleep_duration,
        "Sleep_date_sin": input.Sleep_date_sin,
        "Sleep_date_cos": input.Sleep_date_cos,
        "Wake_date_sin": input.Wake_date_sin,
        "Wake_date_cos": input.Wake_date_cos,
        "Weekday": input.Weekday,
        "Awakenings": input.Awakenings,
        "Irregular_flag": input.Irregular_flag,
        "Alarm_success_rate": input.Alarm_success_rate,
        "model_used": model_used,
        "strength": strength,
        "snooze_count": 0,
        "created_at": firestore.SERVER_TIMESTAMP,
    }

    db.collection("users_kim").document(user_id).collection("Sleep_data").document(date_key).set(doc_data)

    print(f"[Predict] result → model_used={model_used}, strength={strength}")
    print("[Predict] ================================\n")

    # 6) 앱에 반환
    return {
        "model_used": model_used,
        "strength": strength,
    }
