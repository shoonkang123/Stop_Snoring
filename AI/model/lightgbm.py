import pandas as pd
import lightgbm as lgb
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import StratifiedShuffleSplit
from sklearn.utils.class_weight import compute_class_weight
import numpy as np

df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\final_2200_delete_sleep_data.csv")

features = ["Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos", "Sleep_duration", "Awakenings", "Irregular_flag"]
target = "alarm_strength"

df = df.dropna(subset=features + [target])

X = df[features]
Y = df[target]
# alarm_strength + irregular_flag 두 조건을 묶어서 stratify
combined_stratify = Y.astype(str) + "_" + X["Irregular_flag"].astype(str)

splitter = StratifiedShuffleSplit(n_splits=1, test_size=0.2, random_state=42)
for train_idx, test_idx in splitter.split(X, combined_stratify):
    X_train, X_test = X.iloc[train_idx], X.iloc[test_idx]
    y_train, y_test = Y.iloc[train_idx], Y.iloc[test_idx]

classes = np.unique(y_test)
auto_weights = compute_class_weight(class_weight='balanced', classes=classes, y=y_train)
class_weights = dict(zip(classes, auto_weights))
print("\n📊 자동 계산된 클래스 가중치:")
for c in sorted(class_weights):
    print(f"  Class {c}: {class_weights[c]:.4f}")

#✅ (선택) 수동 조정: 클래스 1, 4에 추가 보정
manual_adjust = {1: 2.5, 4: 2.0}  # 필요에 따라 계수 조절 가능
for c, factor in manual_adjust.items():
    if c in class_weights:
        class_weights[c] *= factor
print("\n📊 수동 조정된 최종 클래스 가중치:")
for c in sorted(class_weights):
    print(f"  Class {c}: {class_weights[c]:.4f}")

# ✅ 샘플별 가중치 생성
sample_weights = np.array([class_weights[int(lbl)] for lbl in y_train])

train_data = lgb.Dataset(X_train, label=y_train, weight=sample_weights)
valid_data = lgb.Dataset(X_test, label=y_test)

print(X_train["Irregular_flag"].value_counts(normalize=True))
print(X_test["Irregular_flag"].value_counts(normalize=True))

params = {
    "objective": "multiclass",
    "num_class": 5,
    "metric": "multi_logloss",
    "max_depth": 6,
    "num_leaves": 63,
    "boosting_type": "gbdt",
    "verbosity": -1
}

model = lgb.train(
    params,
    train_data,
    valid_sets=[valid_data],
    num_boost_round=100,
    callbacks=[lgb.early_stopping(10)]
)

y_pred_probs = model.predict(X_test)           # 클래스별 확률
y_pred = y_pred_probs.argmax(axis=1)           # 확률 중 가장 높은 클래스 선택

model.save_model("models/lightGBM_real_alarm_model.txt")
print("모델 저장 완료")

acc = accuracy_score(y_test, y_pred)
print(f"\n✅ 정확도: {acc:.4f}")
print(classification_report(y_test, y_pred))
