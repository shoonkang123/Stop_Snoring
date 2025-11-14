# import pandas as pd
# import numpy as np
#
# df = pd.read_csv(r"C:\Users\kksy0316\Desktop\SLEEP_DATA\raw\kaggle\People_450.csv")
#
# selected = df[["ID", "Bedtime", "Wakeup time", "Sleep duration", "Sleep efficiency",
#                "REM sleep percentage", "Deep sleep percentage", "Light sleep percentage",
#                "Awakenings", "Exercise frequency"]].copy()
#
# # ---------------------------------------------
# # 1️⃣ 날짜+시간 문자열 → pandas datetime으로 변환
# # ---------------------------------------------
# selected["Bedtime_dt"] = pd.to_datetime(selected["Bedtime"], errors="coerce")
# selected["Wakeup_dt"] = pd.to_datetime(selected["Wakeup time"], errors="coerce")
#
# # ---------------------------------------------
# # 2️⃣ datetime에서 시간(hour + minute)만 추출 → 실수형 변환
# # ---------------------------------------------
# selected["Bed_hour"] = selected["Bedtime_dt"].dt.hour + selected["Bedtime_dt"].dt.minute / 60.0
# selected["Wakeup_hour"] = selected["Wakeup_dt"].dt.hour + selected["Wakeup_dt"].dt.minute / 60.0
#
# # ---------------------------------------------
# # 3️⃣ 주기형 인코딩 (24시간 주기)
# # ---------------------------------------------
# selected["Bed_sin"] = np.sin(2 * np.pi * selected["Bed_hour"] / 24)
# selected["Bed_cos"] = np.cos(2 * np.pi * selected["Bed_hour"] / 24)
# selected["Wake_sin"] = np.sin(2 * np.pi * selected["Wakeup_hour"] / 24)
# selected["Wake_cos"] = np.cos(2 * np.pi * selected["Wakeup_hour"] / 24)
#
# # ---------------------------------------------
# # 4️⃣ 필요없는 열 정리
# # ---------------------------------------------
# selected = selected.drop(columns=["Bedtime_dt", "Wakeup_dt", "Bedtime", "Wakeup time"])
#
# # ---------------------------------------------
# # 5️⃣ Snooze_count 규칙 (그대로 유지)
# # ---------------------------------------------
# conditions = [
#     (selected["Sleep efficiency"] >= 0.88) &
#     (selected["Awakenings"] <= 1) &
#     (selected["Deep sleep percentage"] >= 60),
#
#     ((selected["Sleep efficiency"] >= 0.80) & (selected["Sleep efficiency"] < 0.88)) &
#     (selected["Awakenings"] <= 2) &
#     (selected["Deep sleep percentage"] >= 50),
#
#     ((selected["Sleep efficiency"] >= 0.70) & (selected["Sleep efficiency"] < 0.80)) |
#     ((selected["Awakenings"] >= 2) & (selected["Awakenings"] <= 5)) |
#     ((selected["Deep sleep percentage"] >= 40) & (selected["Deep sleep percentage"] < 50)),
#
#     ((selected["Sleep efficiency"] < 0.70) |
#      (selected["Awakenings"] > 5) |
#      (selected["Light sleep percentage"] > 65))
# ]
# choices = [0, 1, 2, 3]
# selected["Snooze_count"] = np.select(conditions, choices, default=1)
#
# # 운동 빈도 보정
# selected.loc[selected["Exercise frequency"] >= 4, "Snooze_count"] = (
#     selected["Snooze_count"] + 1
# ).clip(lower=0)
# selected["Snooze_count"] = selected["Snooze_count"].clip(upper=3)
#
# # 성공/실패 및 강도
# selected["alarm_success"] = (selected["Snooze_count"] <= 2).astype(int)
# selected["alarm_strength"] = 3
#
# # ---------------------------------------------
# # 6️⃣ CSV 저장
# # ---------------------------------------------
# selected.to_csv("alarm_features_clean.csv", index=False, encoding="utf-8")
# print("✅ 변환 완료 — alarm_features_clean.csv 생성됨")
# print(selected[["Bed_hour", "Wakeup_hour"]].head())


import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler, MinMaxScaler
from sklearn.decomposition import PCA

def compute_mean_cov(data: pd.DataFrame, feature_cols: list):
    arr = data[feature_cols].dropna().to_numpy()
    return np.mean(arr, axis=0), np.cov(arr, rowvar=False)

def sample_multivariate_normal(mean_vec, cov_matrix, n_samples):
    return np.random.multivariate_normal(mean=mean_vec, cov=cov_matrix, size=n_samples)

def compute_snooze_score(df, pca_features):
    scaler = StandardScaler()
    X_std = scaler.fit_transform(df[pca_features].dropna())

    pca = PCA(n_components=1)
    PC1 = pca.fit_transform(X_std).flatten()

    flip = np.corrcoef(PC1, df.loc[df[pca_features].notnull().all(axis=1), "Sleep_efficiency"])[0,1] < 0
    if not flip:
        PC1 = -PC1
    print("상관계수:", flip)
    df["snooze_score"] = PC1
    #수면 시간이 길수록 score down, 효율 높을수록 score
    print(pca.components_[0])
    return df

def sample_valid_sin_cos_base_sleep_data(mean_vec, cov_matrix):
    valid_rows = []
    sample = np.random.multivariate_normal(mean_vec, cov_matrix, 1)[0]
    sample_dict = {
        "Sleep_efficiency": sample[0],
        "REM_sleep_percentage": sample[1],
        "Deep_sleep_percentage": sample[2],
        "Light_sleep_percentage": sample[3],
        "Awakenings": sample[4],
        "Exercise_frequency":  sample[5],
        "Bed_sin": sample[6],
        "Bed_cos":  sample[7],
        "Wake_sin":  sample[8],
         "Wake_cos":  sample[9],
        "Bed_hour":  sample[10],
        "Wake_hour":  sample[4],
        "Sleep_duration": sample[4]
    }
    valid_rows.append(sample_dict)
    return pd.DataFrame(valid_rows)


df = pd.read_csv("alarm_features_clean")

sleep_features = ["Sleep_efficiency", "REM_sleep_percentage", "Deep_sleep_percentage",
            "Light_sleep_percentage", "Awakenings", "Exercise_frequency"]
time_features = ["Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos"]

all_feature = sleep_features + time_features

mean_vec, cov_matrix = compute_mean_cov(df, all_feature)

raw_data = sample_valid_sin_cos_base_sleep_data(mean_vec, cov_matrix)
raw_df = pd.DataFrame(raw_data)