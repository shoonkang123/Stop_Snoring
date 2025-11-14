import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

def compute_mean_cov(data: pd.DataFrame, feature_cols: list):
    arr = data[feature_cols].dropna().to_numpy()
    return np.mean(arr, axis=0), np.cov(arr, rowvar=False)

#평균 벡터와 공분산 행렬을 이용하여 다변량 정규분포로 데이터 생성
def sample_multivariate_normal(mean_vec, cov_matrix, n_samples):
    return np.random.multivariate_normal(mean=mean_vec, cov=cov_matrix, size=n_samples)

def apply_postprocessing(df):
    #결측치 제거
    df = df.dropna(subset=["Awakenings"])
    df = df.dropna(subset=["Exercise_frequency"])
    return df

def adjust_score(row):
    score = row["snooze_score_scaled"]  # 0~1 범위
    eff = row["Sleep_efficiency"]
    awake = row["Awakenings"]
    dur = row["Sleep_duration"]

    adjustment = 0.0

    #Sleep_efficiency
    if eff > 0.9:
        adjustment -= 0.05
    elif eff < 0.5:
        adjustment += 0.10

    # Awakenings
    if awake >= 3:
        adjustment += 0.10
    elif awake == 0:
        adjustment -= 0.05

    # Sleep duration
    if dur < 6:
        adjustment += 0.10
    elif dur > 9.5:
        adjustment += 0.10

    return np.clip(score + adjustment, 0, 1)

def compute_snooze_score(df, pca_features):
    # ✅ 2. Sleep_duration 피처만 음수로 반전
    df_mod = df.copy()
    df_mod["Sleep_duration"] = -df_mod["Sleep_duration"]

    # 3. 표준화
    scaler = StandardScaler()
    X_std = scaler.fit_transform(df_mod[pca_features].dropna())

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

def score_to_count(adjusted_score):
    if adjusted_score < 0.2:
        return 0
    elif adjusted_score < 0.5:
        return 1
    elif adjusted_score < 0.8:
        return 2
    else:
        return 3

def make_alarm_strength(df):

    #꺠어남 횟수 정규화 ( 수면 시간 대비 꺠어남 횟수 )
    df["Awakening_per_hour"] = df["Awakenings"] / df["Sleep_duration"]
    #수면 질 관련 피처들
    relation_features = ["Sleep_duration", "Awakening_per_hour", "Irregular_flag"]
    df = df.copy()

    #결측치 처리
    df[relation_features] = df[relation_features].fillna(df[relation_features].mean())
    #스케일링 0~1사이 값
    scaler = StandardScaler()
    X = scaler.fit_transform(df[relation_features])

    #PCA 1축
    pca = PCA(n_components=1)
    base_strength = pca.fit_transform(X).flatten()

    # 피처별 기여도 출력
    loadings = pd.Series(pca.components_[0], index=relation_features)
    print("📈 PCA loadings (피처별 기여도):")
    print(loadings)

    corr = np.corrcoef(base_strength, df["Awakenings"])[0,1]
    if corr < 0:
        base_strength = -base_strength
    #정규화
    base_strength = np.interp(base_strength, (base_strength.min(), base_strength.max()), (1,4))

    df["alarm_strength"] = base_strength.round().astype(int)
    print("✅ PCA 기반 관계형 alarm_strength 라벨링 완료!")
    df.loc[df["Irregular_flag"] == 1, "alarm_strength"] += 1
    df["alarm_strength"] = df["alarm_strength"].clip(1,4)
    print("불규칙 수면자 알람 강도 + 1")
    return df

def generate_snoozecount_alarmstrength_sleep_data(source_csv):
    df = pd.read_csv(source_csv)

    #결측치 제거
    raw_df = apply_postprocessing(df)
    pca_features = [
        "Sleep_duration",
        "Sleep_efficiency",
        "Awakenings",
        "Bed_cos", "Bed_sin",  # 주기적 취침 시각 표현
        "Wake_cos", "Wake_sin"
    ]
    raw_df = compute_snooze_score(raw_df, pca_features)
    raw_df["snooze_score_norm"] = np.tanh(raw_df["snooze_score"])
    raw_df["snooze_score_scaled"] = (raw_df["snooze_score_norm"] + 1) / 2
    raw_df["adjust"] = raw_df.apply(adjust_score, axis=1)
    raw_df["snooze_count"] = raw_df["adjust"].apply(score_to_count)

    raw_df["alarm_success"] = (raw_df["snooze_count"] <= 2).astype(int)
    raw_df["Irregular_flag"] = 0

    raw_df = make_alarm_strength(raw_df)

    round_dict = {
        "Sleep_efficiency": 2,
        "Bed_hour": 2,
        "Wake_hour": 2,
        "Sleep_duration": 2,
        "Bed_sin": 3,
        "Bed_cos": 3,
        "Wake_sin": 3,
        "Wake_cos": 3,
        "snooze_score": 3,
        "snooze_score_norm": 3,
        "snooze_score_scaled": 3,
        "adjust": 3
    }

    for col, n in round_dict.items():
        if col in raw_df.columns:
            raw_df[col] = raw_df[col].round(n)

    raw_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\raw_selected__delete_450.csv", index=False)

if __name__ == "__main__":
    df_synthetic = generate_snoozecount_alarmstrength_sleep_data(source_csv=r"C:\Users\kksy0316\source\repos\Alarm_project\csv\alarm_features_clean.csv")
