import numpy as np
import pandas as pd

df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\synthetic_combined_selected_delete_1750.csv")
raw_df = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\raw_selected_delete_450.csv")

raw_combine_df = pd.concat([raw_df, df], ignore_index=True)
raw_combine_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\2200_delete_sleep_data.csv")

selected_cols = ["ID", "Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos",
                 "Sleep_duration", "Awakenings", "alarm_strength",
                 "alarm_success", "snooze_count","Irregular_flag"]

raw_new_df = raw_df[selected_cols].copy()
new_df = df[selected_cols].copy()

raw_new_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\selected_delete_features_450.csv", index=False)
new_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\selected_delete_features_1750.csv", index=False)
print("완료!")

df_450 = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\selected_delete_features_450.csv")
df_1750 = pd.read_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\selected_delete_features_1750.csv")

combine_df = pd.concat([df_450, df_1750], ignore_index=True)

combine_df.to_csv(r"C:\Users\kksy0316\source\repos\Alarm_project\csv\final_2200_delete_sleep_data.csv", index=False)
print("결합 완료")