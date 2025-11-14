import pandas as pd
import numpy as np
from lightgbm import LGBMRegressor
from sklearn.ensemble import RandomForestRegressor
from catboost import CatBoostRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error

train_df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\2200_delete_sleep_data.csv")

personal_df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\personal_Irregular_sleep.csv")

features = [
    "Sleep_efficiency", "Sleep_duration",
    "Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos", "Irregular_flag"
]

X_awake = train_df[features]
y_awake = train_df["Awakenings"]

X_train, X_val, y_train, y_val = train_test_split(X_awake, y_awake, test_size=0.2, random_state=42)

# model_awake = RandomForestRegressor(
#     n_estimators=500,  # 트리 개수 (200~500 추천)
#     max_depth=None,  # 트리 깊이 제한 없음 (데이터 적을 땐 자동 조정됨)
#     min_samples_split=5,  # 노드 분할 최소 샘플 수
#     min_samples_leaf=1,  # 리프 노드 최소 샘플 수
#     bootstrap=True,
#     random_state=42,
#     n_jobs=-1  # 모든 CPU 코어 사용
# )

model_awake = CatBoostRegressor(
    iterations=600,          # 트리 개수
    learning_rate=0.05,      # 학습률
    depth=2,                 # 트리 깊이 (5~8 정도 추천)
    loss_function='MAE',     # 절대오차(MAE) 최소화 기준
    random_seed=42,
    verbose=100,             # 100번째마다 로그 출력
)

model_awake.fit(X_train, y_train)
pred_awake = model_awake.predict(X_val)
mae_awake = mean_absolute_error(y_val, pred_awake)
print(f"[Awakenings 모델] MAE: {mae_awake:.3f}")

personal_df["Awakenings"] = model_awake.predict(personal_df[features])
personal_df["Awakenings"] = np.clip(personal_df["Awakenings"], 0, None).round(0).astype(int)

# ==========================================
# 6️⃣ 결과 저장
# ==========================================
personal_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\Irregular_personal_sleep_with_awake.csv", index=False, float_format="%.2f")
