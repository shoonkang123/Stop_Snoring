import pandas as pd
import numpy as np

# 1️⃣ CSV 읽기 (세미콜론 기준 + BOM 자동 제거)
df = pd.read_csv(r"C:\Users\kksy0316\Desktop\Alarm_APP\sleepdata.csv", sep=";", encoding="utf-8-sig")

# 2️⃣ 컬럼 이름 실제로 확인
print("📋 원본 컬럼명:", list(df.columns))

# 3️⃣ 숨은 문자 제거 (가장 중요한 부분!)
df.columns = df.columns.str.replace('\ufeff', '', regex=False).str.strip()

# 4️⃣ 다시 확인
print("✅ 정리된 컬럼명:", list(df.columns))

# 5️⃣ 컬럼 이름 통일
df.columns = ["Start", "End", "Sleep_quality", "Time_in_bed",
              "Wake_up", "Sleep_Notes", "Heart_rate", "Activity_steps"]

# 6️⃣ 변환 및 계산
df["Start"] = pd.to_datetime(df["Start"], errors="coerce")
df["End"] = pd.to_datetime(df["End"], errors="coerce")

df["Bed_minutes"] = df["Start"].dt.hour * 60 + df["Start"].dt.minute
df["Bed_sin"] = np.sin(2 * np.pi * df["Bed_minutes"] / 1440)
df["Bed_cos"] = np.cos(2 * np.pi * df["Bed_minutes"] / 1440)
df["Wake_minutes"] = df["End"].dt.hour * 60 + df["End"].dt.minute
df["Wake_sin"] = np.sin(2 * np.pi * df["Wake_minutes"] / 1440)
df["Wake_cos"] = np.cos(2 * np.pi * df["Wake_minutes"] / 1440)

df["Weekday"] = df["Start"].dt.weekday  # 0=월, 6=일
df["Sleep_date"] = df["Start"].dt.date        # 날짜 (연-월-일)
df["Wake_date"] = df["End"].dt.date

df["Sleep_efficiency"] = df["Sleep_quality"].astype(str).str.replace("%", "")
df["Sleep_efficiency"] = pd.to_numeric(df["Sleep_efficiency"], errors="coerce") / 100
df["Exercise"] = pd.to_numeric(df["Activity_steps"], errors="coerce")
df["Sleep_duration"] = np.trunc((df["End"] - df["Start"]).dt.total_seconds() / 36) / 100
df["Irregular_flag"] = 0

df = df.drop(columns=["Bed_minutes", "Wake_minutes", "Time_in_bed", "Heart_rate",
                      "Activity_steps", "Sleep_Notes", "Sleep_quality", "Start",
                      "End", "Wake_up"])

# 7️⃣ 저장
df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\personal_sleep.csv", index=False, encoding="utf-8-sig")
print("✅ CSV 클리닝 완료 → personal_sleep.csv 저장됨")
