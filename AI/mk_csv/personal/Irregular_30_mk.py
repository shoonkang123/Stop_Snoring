import pandas as pd
import numpy as np
import math
from datetime import datetime, timedelta

# 원본 불러오기
df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\personal_sleep.csv")
df = df[df["Sleep_duration"] > 5].reset_index(drop=True)
# 사용할 피처
features = ["Sleep_date", "Sleep_efficiency", "Exercise", "Sleep_duration"]
df = df[features]

# 날짜 변환
df["Sleep_date"] = pd.to_datetime(df["Sleep_date"])

new_data = []

for i, row in df.iterrows():
    # ✅ 1. 불규칙 취침 시각 (18~30시)
    bed_hour = np.random.uniform(0, 24)

    # ✅ 2. 기상 시각 = 취침 + 수면시간
    wake_hour = bed_hour + row["Sleep_duration"]
    wake_date = row["Sleep_date"]

    # 24시 넘어가면 날짜 하루 증가
    if wake_hour >= 24:
        wake_hour -= 24
        wake_date += timedelta(days=1)

    # ✅ 3. 인코딩 계산
    bed_sin = round(math.sin(2 * math.pi * bed_hour / 24), 4)
    bed_cos = round(math.cos(2 * math.pi * bed_hour / 24), 4)
    wake_sin = round(math.sin(2 * math.pi * wake_hour / 24), 4)
    wake_cos = round(math.cos(2 * math.pi * wake_hour / 24), 4)

    # ✅ 4. 요일 계산 (0=월 ~ 6=일)
    weekday = wake_date.weekday()

    # ✅ 5. Irregular_flag = 1 (불규칙자)
    irregular_flag = 1

    # ✅ 6. 최종 저장
    new_data.append({
        "Bed_hour": round(bed_hour, 2),
        "Wake_hour": round(wake_hour, 2),
        "Bed_sin": bed_sin,
        "Bed_cos": bed_cos,
        "Wake_sin": wake_sin,
        "Wake_cos": wake_cos,
        "Weekday": weekday,
        "Sleep_date": row["Sleep_date"].strftime("%Y-%m-%d"),
        "Wake_date": wake_date.strftime("%Y-%m-%d"),
        "Sleep_efficiency": row["Sleep_efficiency"],
        "Exercise": row["Exercise"],
        "Sleep_duration": row["Sleep_duration"],
        "Irregular_flag": irregular_flag
    })

# ✅ 7. DataFrame 생성
irregular_df = pd.DataFrame(new_data)
irregular_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\personal_irregular_sleep.csv", index=False)

print("✅ 불규칙 수면자 변환 완료!")
print(irregular_df.head(10))
