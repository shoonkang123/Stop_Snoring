import pandas as pd

# CSV 읽기
df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\Irregular_personal_sleep_with_complete.csv")

# 필요한 열만 선택
features = df[[
    "Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos", "Weekday",
    "Sleep_duration", "Irregular_flag", "Awakenings",
    "Sleep_date_sin", "Sleep_date_cos", "Wake_date_sin", "Wake_date_cos"
]]

# ✅ 31행(0부터 시작이므로 실제 32번째 데이터)
sample_row = features.iloc[[30]]  # DataFrame으로 유지

# ✅ 열 이름 + 값 한 줄씩 저장
save_path = r"C:\Users\kksy0316\source\repos\Alarm_project\csv\Irregular_personal_oneday.csv"
sample_row.to_csv(save_path, index=False, encoding="utf-8-sig")

print("✅ 31행 데이터만 저장 완료 (열 이름 + 값)")
