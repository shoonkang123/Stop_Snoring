import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA

#df 열(속성) 값의 결측치를 제거 후 속성들의 평균 벡터 및 공분산 행렬 반환
def compute_mean_cov(data: pd.DataFrame, feature_cols: list):
    arr = data[feature_cols].dropna().to_numpy()
    return np.mean(arr, axis=0), np.cov(arr, rowvar=False)

#평균 벡터와 공분산 행렬을 이용하여 다변량 정규분포로 데이터 생성
def sample_multivariate_normal(mean_vec, cov_matrix, n_samples):
    return np.random.multivariate_normal(mean=mean_vec, cov=cov_matrix, size=n_samples)

def normalize_sleep_stages(df):
    # Stage 비율 보정 (클리핑 + 합이 100 되도록)
    #.clip으로 범위 조절
    REM = df["REM_sleep_percentage"].clip(15, 30)
    Deep = df["Deep_sleep_percentage"].clip(18, 75)
    Light = df["Light_sleep_percentage"].clip(7, 63)
    total = REM + Deep + Light
    #합이 100%로가 되도록 조절
    df["REM_sleep_percentage"] = REM / total * 100
    df["Deep_sleep_percentage"] = Deep / total * 100
    df["Light_sleep_percentage"] = Light / total * 100
    return df

def apply_postprocessing(df):
    #결측치 제거
    df = df.dropna(subset=["Awakenings"])
    if "Awakenings" in df.columns:
        df["Awakenings"] = (
            pd.to_numeric(df["Awakenings"], errors="coerce")
            .clip(lower=0, upper=4) #0보다 작은 값은 0으로
            .round()  # 반올림
            .astype(int)  # 정수 변환
        )

        # 2️⃣ Sleep_efficiency 정리
    if "Sleep_efficiency" in df.columns:
        df["Sleep_efficiency"] = (
            pd.to_numeric(df["Sleep_efficiency"], errors="coerce")
            .fillna(0.65)  # 결측 값을 0.65로 대체
            .clip(0.6, 0.96) #범위 제한
        )
    return df

def compute_snooze_score(df, pca_features):
    df_mod = df.copy()
    df_mod["Sleep_duration"] = -df_mod["Sleep_duration"]

    # 3. 표준화
    scaler = StandardScaler()
    X_std = scaler.fit_transform(df_mod[pca_features].dropna())

    pca = PCA(n_components=1)
    PC1 = pca.fit_transform(X_std).flatten()
    flip = np.corrcoef(PC1, df.loc[df[pca_features].notnull().all(axis=1), "Sleep_efficiency"])[0,1] < 0
    if not flip:
        PC1 = PC1
    print("상관계수:", flip)
    df["snooze_score"] = PC1
    #수면 시간이 길수록 score down, 효율 높을수록 score
    print(pca.components_[0])
    return df

def radians_to_hour(sin_val, cos_val):
    """
    사인/코사인 값으로부터 0~24 사이의 시간(hour)을 복원하는 함수
    """
    angle = np.arctan2(sin_val, cos_val)  # [-π, π]
    if angle < 0:
        angle += 2 * np.pi  # [0, 2π]
    hour = angle / (2 * np.pi) * 24
    return hour

def is_valid_time_range(bed_hour, wake_hour, min_sleep=3, max_sleep=13):
    sleep_duration = (wake_hour - bed_hour) % 24
    return (21 <= bed_hour <= 26.5) and (3 <= wake_hour <= 12.5) and (min_sleep <= sleep_duration <= max_sleep)

def sample_valid_sin_cos_base_sleep_data(mean_vec, cov_matrix, n_samples):
    valid_rows = []
    max_attempts = n_samples * 100
    attempts = 0
    while len(valid_rows) < n_samples and attempts < max_attempts:
        sample = np.random.multivariate_normal(mean_vec, cov_matrix, 1)[0]
        exercise = sample[5]
        bed_sin, bed_cos = sample[6], sample[7]
        wake_sin, wake_cos = sample[8], sample[9]

        if exercise < 0:
            attempts += 1
            continue

        # 시간 복원
        bed_hour = radians_to_hour(bed_sin, bed_cos)
        wake_hour = radians_to_hour(wake_sin, wake_cos)

        if is_valid_time_range(bed_hour, wake_hour):
            sample_dict = {
                "Sleep_efficiency": sample[0],
                "REM_sleep_percentage": sample[1],
                "Deep_sleep_percentage": sample[2],
                "Light_sleep_percentage": sample[3],
                "Awakenings": sample[4],
                "Exercise_frequency": exercise,
                "Bed_sin": bed_sin,
                "Bed_cos": bed_cos,
                "Wake_sin": wake_sin,
                "Wake_cos": wake_cos,
                "Bed_hour": bed_hour,
                "Wake_hour": wake_hour,
                "Sleep_duration": (wake_hour - bed_hour) % 24
            }
            valid_rows.append(sample_dict)
        attempts += 1
    return pd.DataFrame(valid_rows)

def adjust_score(row):
    score = row["snooze_score_scaled"]  # 0~1 범위
    eff = row["Sleep_efficiency"]
    awake = row["Awakenings"]
    ex = row["Exercise_frequency"]
    dur = row["Sleep_duration"]
    deep = row["Deep_sleep_percentage"]
    light = row["Light_sleep_percentage"]

    adjustment = 0.0

    #Sleep_efficiency
    if eff > 0.9:
        adjustment -= 0.05
    elif eff < 0.5:
        adjustment += 0.05

    #Light_sleep_percentage
    if light > 45:
        adjustment += 0.05
    elif light < 15:
        adjustment -= 0.05

    # Deep_sleep_percentage
    if deep > 65:
        adjustment -= 0.05
    elif deep < 35:
        adjustment += 0.05

    # Awakenings
    if awake >= 3:
        adjustment += 0.05
    elif awake == 0:
        adjustment -= 0.05

    # Exercise_frequency
    if ex >= 4:
        adjustment -= 0.05
    elif ex <= 1:
        adjustment += 0.05

    # Sleep duration
    if dur < 6:
        adjustment += 0.05
    elif dur >9.5:
        adjustment += 0.05

    return np.clip(score + adjustment, 0, 1)

def score_to_count(adjusted_score):
    if adjusted_score < 0.2:
        return 0
    elif adjusted_score < 0.5:
        return 1
    elif adjusted_score < 0.8:
        return 2
    else:
        return 3

#alarm_strength라벨링(규칙 기반 + 관계 기반으로 라벨링)
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

#블규칙 수면자 데이터 생성
def sample_irregular_sleep_data(df, mean_vec, cov_matrix, n_irregular=250):
    valid_rows = []
    attempts = 0
    max_attempts = n_irregular * 200

    while len(valid_rows) < n_irregular and attempts < max_attempts:
        sample = np.random.multivariate_normal(mean_vec, cov_matrix, 1)[0]
        bed_sin, bed_cos = sample[6], sample[7]
        wake_sin, wake_cos = sample[8], sample[9]
        exercise = sample[5]

        if exercise < 0:  # 운동 음수 제거
            attempts += 1
            continue

        bed_hour = radians_to_hour(bed_sin, bed_cos)
        wake_hour = radians_to_hour(wake_sin, wake_cos)
        sleep_duration = (wake_hour - bed_hour) % 24

        # ✅ 불규칙자 조건: 평균 범위 벗어남 + 현실적인 수면 시간만 허용
        if ((bed_hour < 21 or bed_hour > 26.5) or (wake_hour < 3 or wake_hour > 12.5)) and (3 <= sleep_duration <= 13):
            sample_dict = {
                "Sleep_efficiency": sample[0],
                "REM_sleep_percentage": sample[1],
                "Deep_sleep_percentage": sample[2],
                "Light_sleep_percentage": sample[3],
                "Awakenings": int(sample[4]),
                "Exercise_frequency": exercise,
                "Bed_sin": bed_sin,
                "Bed_cos": bed_cos,
                "Wake_sin": wake_sin,
                "Wake_cos": wake_cos,
                "Bed_hour": bed_hour,
                "Wake_hour": wake_hour,
                "Sleep_duration": sleep_duration
            }
            valid_rows.append(sample_dict)

        attempts += 1

    print(f"✅ 불규칙 수면자 {len(valid_rows)}명 생성 완료 ({attempts}회 시도)")
    return pd.DataFrame(valid_rows)

def generate_synthetic_sleep_data(
    source_csv="raw_mk_snooze_strength.csv",
    n_regular=1500,
    n_irregular=250,
    save_path_regular=r"C:\Users\kksy0316\source\repos\Alarm_project\csv\synthetic_selected_1500.csv",
    save_path_irregular=r"C:\Users\kksy0316\source\repos\Alarm_project\csv\synthetic_irregular_selected_250.csv",
    save_path_combined=r"C:\Users\kksy0316\source\repos\Alarm_project\csv\synthetic_combined_selected_1750.csv",
    start_id=453
):
    df = pd.read_csv(source_csv)

    #수면 품질 관리 피처들
    sleep_features = ["Sleep_efficiency", "REM_sleep_percentage", "Deep_sleep_percentage",
            "Light_sleep_percentage", "Awakenings", "Exercise_frequency"]
    time_features = ["Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos"]
    all_features = sleep_features + time_features

    # 평균/공분산
    mean_vec, cov_matrix = compute_mean_cov(df, all_features)

    # 다변량 샘플링
    reg_df = sample_valid_sin_cos_base_sleep_data(mean_vec, cov_matrix, n_regular)
    # 전처리
    reg_df = normalize_sleep_stages(reg_df)
    reg_df = apply_postprocessing(reg_df)
    reg_df["ID"] = list(range(start_id, start_id+n_regular))
    reg_df["Irregular_flag"] = 0
    #불규칙 수면자
    irreg_df = sample_irregular_sleep_data(df, mean_vec, cov_matrix, n_irregular=250)
    irreg_df = normalize_sleep_stages(irreg_df)
    irreg_df = apply_postprocessing(irreg_df)
    irreg_df["ID"] = list(range(start_id + n_regular, start_id + n_regular + n_irregular))
    irreg_df["Irregular_flag"] = 1

    #공통 스누즈 계싼
    pca_features = [
        "Sleep_duration",
        "Sleep_efficiency",
        "Deep_sleep_percentage",
        "REM_sleep_percentage",  # Light_sleep_percentage와 상호보완
        "Awakenings",
        "Exercise_frequency",
        "Bed_cos", "Bed_sin",  # 주기적 취침 시각 표현
        "Wake_cos", "Wake_sin"
    ]

    for sub_df in [reg_df, irreg_df]:
        # snooze_score가 낮을수록 기상 성공 가능성이 높음
        sub_df = compute_snooze_score(sub_df, pca_features)
        # 비선형 변환 tanh 결과-1~1
        sub_df["snooze_score_norm"] = np.tanh(sub_df["snooze_score"])
        sub_df["snooze_score_scaled"] = (sub_df["snooze_score_norm"] + 1) / 2
        sub_df["adjust"] = sub_df.apply(adjust_score, axis=1)
        sub_df["snooze_count"] = sub_df["adjust"].apply(score_to_count)
        # 스누즈 횟수 2회 이하 일시에는 기상 성공
        # 0이 실패 1이 성공
        sub_df["alarm_success"] = (sub_df["snooze_count"] <= 2).astype(int)

    reg_df = make_alarm_strength(reg_df)
    irreg_df = make_alarm_strength(irreg_df)

    round_dict = {
        "Sleep_efficiency": 2,
        "REM_sleep_percentage": 2,
        "Deep_sleep_percentage": 2,
        "Light_sleep_percentage": 2,
        "Bed_hour": 2,
        "Wake_hour": 2,
        "Exercise_frequency": 0,
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
        if col in reg_df.columns:
            reg_df[col] = reg_df[col].round(n)
    for col, n in round_dict.items():
        if col in irreg_df.columns:
            irreg_df[col] = irreg_df[col].round(n)
    # 저장 (보기 좋게)
    reg_df.to_csv(save_path_regular, index=False)
    irreg_df.to_csv(save_path_irregular, index=False)

    # === (4) 병합 ===
    combined_df = pd.concat([reg_df, irreg_df], ignore_index=True)
    combined_df.to_csv(save_path_combined, index=False)

    print(f"✅ 규칙 수면자 {n_regular}명, 불규칙 수면자 {n_irregular}명 생성 완료")
    print(f"   → Regular: {save_path_regular}")
    print(f"   → Irregular: {save_path_irregular}")
    print(f"   → Combined: {save_path_combined}")

    return combined_df

if __name__ == "__main__":
    df_synthetic = generate_synthetic_sleep_data(
        source_csv= r"C:\Users\kksy0316\source\repos\Alarm_project\csv\alarm_features_clean.csv",
        n_regular=1500,
        n_irregular=250,
        start_id=453
    )