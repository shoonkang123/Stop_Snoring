from fastapi import FastAPI
from pydantic import BaseModel
import lightgbm as lgb
import numpy as np
import pandas as pd
import joblib
import torch
import firebase_admin
from firebase_admin import credentials, firestore
from AI.model.Personalize_freeze import train_transferModel
from AI.model.Personalize_freeze import transferModel
from datetime import datetime, timezone

# fire base 부분
# 서비스 키 받아오기
cred = credentials.Certificate(r"C:\git_test_alarm\Stop_Snoring\firebase\pasnallized-alarm-service-firebase-adminsdk-fbsvc-c001641e27.json")
# firebase 앱 초기화
firebase_admin.initialize_app(cred)
# firesotre 클라이언트 생성
db = firestore.client()

app = FastAPI()

device = "cuda" if torch.cuda.is_available() else "cpu"

# ligthGBM모델 가중치 로드
model_lightgbm = lgb.Booster(model_file="AI/weight_pt/lightGBM_real_alarm_model.txt")
model_lstm = transferModel()
# 추후 개인 사용자 데이터 30일치 생기면 이 부분 수정 해야 함
ckpt_personal = torch.load(r"C:\git_test_alarm\Stop_Snoring\AI\weight_pt\personalized_model.pt", map_location=device)
model_lstm.load_state_dict(ckpt_personal)



# # 입력 데이터 정의
# class LightGBMFeatures(BaseModel):
#     Bed_sin: float
#     Bed_cos: float
#     Wake_sin: float
#     Wake_cos: float
#     Sleep_duration: float
#     Awakenings: int
#     Irregular_flag: int

# class LSTMFeatures(BaseModel):
#     Bed_sin: float
#     Bed_cos: float
#     Wake_sin: float
#     Wake_cos: float
#     Sleep_duration: float
#     Sleep_date_sin: float
#     Sleep_date_cos: float
#     Wake_date_sin: float
#     Wake_date_cos: float
#     Weekday: int
#     Awakenings: int
#     Irregular_flag: int
#     Alarm_success_rate: float

# class LSTMFeaturesDF:
#     @staticmethod
#     def to_dataframe(data: LSTMFeatures) -> pd.DataFrame:
#         df = pd.DataFrame([{
#             "Bed_sin": data.Bed_sin,
#             "Bed_cos": data.Bed_cos,
#             "Wake_sin": data.Wake_sin,
#             "Wake_cos": data.Wake_cos,
#             "Sleep_duration": data.Sleep_duration,
#             "Sleep_date_sin": data.Sleep_date_sin,
#             "Sleep_date_cos": data.Sleep_date_cos,
#             "Wake_date_sin": data.Wake_date_sin,
#             "Wake_date_cos": data.Wake_date_cos,
#             "Weekday": data.Weekday,
#             "Awakenings": data.Awakenings,
#             "Irregular_flag": data.Irregular_flag,
#             #"snooze_count": data.snooze_count, # 보정 피처
#             #"alarm_strength": data.alarm_strength
#         }])
#         return df


# # AI 모델 입력 데이터로 firestore에서 값을 불러올 때
# def read_user(user_id: str):
#     doc = db.collection("users").document(user_id).get()
#     return doc.to_dict()


# # firestore 데이터로 바로 예측하는 함수
# @app.get("/predict_firestore/{user_id}")
# def predict_alarm_firestore(user_id: str):
#     try:
#         data = read_user(user_id)
#         for key, value in data.items():
#             print(f"🔍 {key} => type: {type(value)}, value: {value}")

#         lgb_input = dict_to_lightgbm_features(data)
#         lstm_input = dict_to_lstm_features(data)
#         # 1행 7열
#         lgb_features = np.array([
#             lgb_input.Bed_sin,
#             lgb_input.Bed_cos,
#             lgb_input.Wake_sin,
#             lgb_input.Wake_cos,
#             lgb_input.Sleep_duration,
#             lgb_input.Awakenings,
#             lgb_input.Irregular_flag
#         ]).reshape(1, -1)

#         probs = model_lightgbm.predict(lgb_features)[0]
#         lgb_pred = int(np.argmax(probs)+1)
#         # 1차원 벡터
#         lstm_features = np.array([
#             lstm_input.Bed_sin,
#             lstm_input.Bed_cos,
#             lstm_input.Wake_sin,
#             lstm_input.Wake_cos,
#             lstm_input.Weekday,
#             lstm_input.Sleep_duration,
#             lstm_input.Irregular_flag,
#             lstm_input.Awakenings,
#             lstm_input.Sleep_date_sin,
#             lstm_input.Sleep_date_cos,
#             lstm_input.Wake_date_sin,
#             lstm_input.Wake_date_cos
#         ], dtype=np.float32).reshape(1, -1)

#         input_tensor = torch.tensor(lstm_features).unsqueeze(0).to(device)
#         print(f"LSTM input shape: {input_tensor.shape}")
#         with torch.no_grad():
#             model_lstm.eval().to(device)
#             output = model_lstm(input_tensor)
#             output = output.squeeze(0)
#             probs = torch.softmax(output, dim=1)
#             lstm_pred = torch.argmax(probs, dim=1).item() + 1
#             # 평균 알람 성공률 피처를 어떻게 가져올 지 생각해야 햠
#             if lstm_input.Alarm_success_rate < 0.5:
#                 pred_class = min(lstm_pred + 1, 4)
#         result = {
#             "LightGBM_strength": lgb_pred,
#             "LSTM_strength": lstm_pred
#         }

#         # Firestore에 저장
#         db.collection("users").document(user_id).collection("predictions").add(result)

#         # 앱에 반환
#         return result
#     except Exception as e:
#         return {"error": str(e)}


# # firestore 데이터를 lightgbm 모델의 입력 값에 맞게 변경
# def dict_to_lightgbm_features(data: dict) -> PredictInput:
#     return PredictInput(
#         user_id=str(data["user_id"]),
#         Bed_sin=float(data["Bed_sin"]),
#         Bed_cos=float(data["Bed_cos"]),
#         Wake_sin=float(data["Wake_sin"]),
#         Wake_cos=float(data["Wake_cos"]),
#         Sleep_duration=float(data["Sleep_duration"]),
#         Awakenings=int(data["Awakenings"]),
#         Irregular_flag=int(data["Irregular_flag"])
#     )
# # firestore 데이터를 lstm 모델의 입력 값에 맞게 변경
# def dict_to_lstm_features(data: dict) -> PredictInput:
#     return PredictInput(
#         user_id = str(data["user_id"]),
#         Bed_sin=float(data["Bed_sin"]),
#         Bed_cos=float(data["Bed_cos"]),
#         Wake_sin=float(data["Wake_sin"]),
#         Wake_cos=float(data["Wake_cos"]),
#         Sleep_duration=float(data["Sleep_duration"]),
#         Sleep_date_sin=float(data["Sleep_date_sin"]),
#         Sleep_date_cos=float(data["Sleep_date_cos"]),
#         Wake_date_sin=float(data["Wake_date_sin"]),
#         Wake_date_cos=float(data["Wake_date_cos"]),
#         Weekday=int(data["Weekday"]),
#         Awakenings=int(data["Awakenings"]),
#         Irregular_flag=int(data["Irregular_flag"]),
#         Alarm_success_rate=float(data["Alarm_success_rate"])
#     )

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


class LSTMFeaturesDF:
    @staticmethod
    def to_dataframe(data: PredictInput) -> pd.DataFrame:
        df = pd.DataFrame([{
            "user_id": data.user_id,
            "Bed_sin": data.Bed_sin,
            "Bed_cos": data.Bed_cos,
            "Wake_sin": data.Wake_sin,
            "Wake_cos": data.Wake_cos,
            "Sleep_duration": data.Sleep_duration,
            "Sleep_date_sin": data.Sleep_date_sin,
            "Sleep_date_cos": data.Sleep_date_cos,
            "Wake_date_sin": data.Wake_date_sin,
            "Wake_date_cos": data.Wake_date_cos,
            "Weekday": data.Weekday,
            "Awakenings": data.Awakenings,
            "Irregular_flag": data.Irregular_flag,
            #"snooze_count": data.snooze_count, # 보정 피처
            #"alarm_strength": data.alarm_strength
        }])
        return df

# LSTM 모델 학습(개인 사용자 30일 데이터)
@app.post("/train-personal-model")
def train_personal(data: PredictInput):
    try:
        df = LSTMFeaturesDF.to_dataframe(data)
        train_transferModel(df)
        return {"message": "Training completed successfully"}
    except Exception as e:
        return {"error": str(e)}

    
@app.post("/Predict")
def predict_alarm(input: PredictInput):

    user_id = input.user_id

    #firestore에서 수면 기록 개수 확인
    logs_ref = (
        db.collection("users_kim")
        .document(user_id)
        .collection("Sleep_data")
        .get()
    )
    total_logs = len(logs_ref)

    use_lstm = total_logs >= 30
    model_used = ""
    strength = 0

    if not use_lstm:
        #lightGBM 입력 피처
        lgb_features = np.array([
            input.Bed_sin,
            input.Bed_cos,
            input.Wake_sin,
            input.Wake_cos,
            input.Sleep_duration,
            input.Awakenings,
            input.Irregular_flag
        ]).reshape(1, -1)

        probs = model_lightgbm.predict(lgb_features)[0]
        lgb_pred = int(np.argmax(probs) + 1)

        model_used = "LightGBM"
        strength = lgb_pred

    else:
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
            input.Wake_date_cos
        ], dtype=np.float32).reshape(1, -1)

        input_tensor = torch.tensor(lstm_features).unsqueeze(0).to(device)
        
        with torch.no_grad():
            model_lstm.eval().to(device)
            output = model_lstm(input_tensor)
            output = output.squeeze(0)
            probs = torch.softmax(output, dim=1)
            lstm_pred = torch.argmax(probs, dim=1).item() + 1
            # 평균 알람 성공률 피처를 어떻게 가져올 지 생각해야 햠
            if input.Alarm_success_rate < 0.5:
                lstm_pred = min(lstm_pred + 1, 4)

        model_used = "LSTM"
        strength = lstm_pred

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
        "created_at": firestore.SERVER_TIMESTAMP,
    }

    # firestore에 저장
    db.collection("users_kim").document(user_id).collection("Sleep_data").document(date_key).set(doc_data)

    # 앱에 반환
    return {
        "model_used": model_used,
        "strength": strength,
    }
