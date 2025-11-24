import pandas as pd
from firebase_admin import credentials, firestore, initialize_app

cred = credentials.Certificate(r"C:\git_test_alarm\Stop_Snoring\firebase\pasnallized-alarm-service-firebase-adminsdk-fbsvc-c001641e27.json")
initialize_app(cred)
db = firestore.client()

csv_path = r"C:\Users\didck\Downloads\Irregular_personal_30day_utc_hhmm.csv"
df = pd.read_csv(csv_path)

# 3) 업로드할 Firestore 경로 설정 -------------------------
user_id = "kim"   # 실제 userId로 교체
sleep_col = (
    db.collection("users_kim")
      .document(user_id)
      .collection("Sleep_data")
)

# 4) 각 행(row) → 문서 하나씩 만들기 ---------------------
# 문서 ID 형태 예시: 2014-12-30_13-43
for _, row in df.iterrows():
    # ① 문서 ID 만들기 (날짜 + 취침시간 등 원하는 규칙)
    sleep_date = str(row["Sleep_date"])     # 예: 2014-12-30
    bed_time   = str(row["Bed_UTC_HHMM"])   # 예: 13:43  (UTC 기준 or KST 기준 원하는 것)
    doc_id = f"{sleep_date}_{bed_time.replace(':', '-')}"  # 2014-12-30_13-43

    # ② 실제로 저장할 필드들 선택
    #   (CSV에 있는 컬럼명을 그대로 쓰면 됨)
    field_names = [
        "Awakenings",
        "Bed_cos", "Bed_sin",
        "Wake_cos", "Wake_sin",
        "Weekday",
        "Sleep_duration",
        "Irregular_flag",
        "Sleep_date_sin", "Sleep_date_cos",
        "Wake_date_sin", "Wake_date_cos",
        # 🔴 여기서 alarm_strength는 빼고
        "alarm_success",
        "snooze_count",
        "Bed_UTC_HHMM", "Wake_UTC_HHMM",
    ]

    data = row[field_names].to_dict()

    # 🔹 CSV의 alarm_strength 값을 Firestore에서는 strength라는 이름으로 저장
    data["strength"] = int(row["alarm_strength"])


    # ③ Firestore에 쓰기
    sleep_col.document(doc_id).set(data)

print("모든 CSV 행이 Sleep_data에 업로드 완료!")