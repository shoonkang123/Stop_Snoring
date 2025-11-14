from fastapi import FastAPI
from pydantic import BaseModel
import lightgbm as lgb
import numpy as np
import pandas as pd
import joblib
import torch

from AI.model.Personalize_freeze import train_transferModel
from AI.model.Personalize_freeze import transferModel

app = FastAPI()

device = "cuda" if torch.cuda.is_available() else "cpu"

# ligthGBM모델 가중치 로드
model_lightgbm = lgb.Booster(model_file="AI/weight_pt/lightGBM_real_alarm_model.txt")
model_lstm = transferModel()
# 사전 학습 가중치 로드
ckpt_feature_extractor = torch.load("AI/weight_pt/feature_extractor_real_pretrained_batchnorm.pt", map_location=device)
model_lstm.feature_extractor.load_state_dict(ckpt_feature_extractor)
# 추후 개인 사용자 데이터 30일치 생기면 이 부분 수정 해야 함
ckpt_personal = torch.load("AI/weight_pt/Pretrain_lstm_snooze.pt", map_location=device)
model_lstm.load_state_dict(ckpt_personal)
model_lstm.eval().to(device)


# 입력 데이터 정의
class LightGBMFeatures(BaseModel):
    Bed_sin: float
    Bed_cos: float
    Wake_sin: float
    Wake_cos: float
    Sleep_duration: float
    Awakenings: int
    Irregular_flag: int

class LSTMFeatures(BaseModel):
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
    snooze_count: int
    alarm_strength: int

class PredictRequest(BaseModel):
    lgb_features: LightGBMFeatures
    lstm_features: LSTMFeatures

class LSTMFeaturesDF:
    @staticmethod
    def to_dataframe(data: LSTMFeatures) -> pd.DataFrame:
        df = pd.DataFrame([{
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
            "snooze_count": data.snooze_count, # 보정 피처
            "alarm_strength": data.alarm_strength
        }])
        return df

# LightGBM 예측
@app.post("/predict_lightgbm")
def lightgbm_predict(request: PredictRequest):
    try:
        features = np.array([
            request.lgb_features.Bed_sin,
            request.lgb_features.Bed_cos,
            request.lgb_features.Wake_sin,
            request.lgb_features.Wake_cos,
            request.lgb_features.Sleep_duration,
            request.lgb_features.Awakenings,
            request.lgb_features.Irregular_flag
        ]).reshape(1, -1)
        output = model_lightgbm.predict(features)
        alarm_strength = int(output[0])
        return {"Alarm_strength": alarm_strength}
    except Exception as e:
        return {"error": str(e)}

# LSTM 예측
@app.post("/predict_lstm")
def lstm_predict(request: PredictRequest):
    try:
        features = np.array([
            request.lstm_features.Bed_sin,
            request.lstm_features.Bed_cos,
            request.lstm_features.Wake_sin,
            request.lstm_features.Wake_cos,
            request.lstm_features.Sleep_date_sin,
            request.lstm_features.Sleep_date_cos,
            request.lstm_features.Wake_date_sin,
            request.lstm_features.Wake_date_cos,
            request.lstm_features.Weekday,
            request.lstm_features.Irregular_flag,
            request.lstm_features.Sleep_duration,
            request.lstm_features.Awakenings
        ], dtype=np.float32)
        # LSTM은 [batch, seq_len, feature_dim] 형태
        input_tensor = torch.tensor(features).unsqueeze(0).to(device)
        with torch.no_grad():
            output = model_lstm(input_tensor)
            output = output.squeeze(0)
            probs = torch.softmax(output, dim=0)
            pred_class = torch.argmax(probs).item() + 1

            if request.lstm_features.Alarm_success_rate < 0.5:
                pred_class = min(pred_class + 1, 4)

        return {"Alarm_strength": pred_class}
    except Exception as e:
        return {"error": str(e)}

# LSTM 모델 학습(개인 사용자 30일 데이터)
@app.post("/train-personal-model")
def train_personal(data: LSTMFeatures):
    try:
        df = LSTMFeaturesDF.to_dataframe(data)
        train_transferModel(df)
        return {"success"}
    except Exception as e:
        return {"error": str(e)}
