import pandas as pd
import torch
import torch.nn as nn
import torch.optim as optim
from AI.model.Pretrain import FeatureExtractor
from collections import Counter

class transferModel(nn.Module):
    def __init__(self, transfer_input_size=12, pretrain_input_size = 12,
                 embedding_size=32, hidden_size=64, num_classes=4):
        super().__init__()
        self.feature_extractor = FeatureExtractor(pretrain_input_size, embedding_size)
        self.lstm = nn.LSTM(embedding_size, hidden_size, batch_first=True)
        self.fc_out = nn.Linear(hidden_size, num_classes)

    def forward(self, x_seq):
        batch, seq_len, _ = x_seq.shape
        x_seq = x_seq.reshape(batch * seq_len, -1)
        z = self.feature_extractor(x_seq)
        z = z.view(batch, seq_len, -1)
        lstm_out, _ = self.lstm(z)
        out = self.fc_out(lstm_out)
        #학습 시 : 1,30,4, 개인 데이터 : 1,1,4
        return out

def train_transferModel(df):
    lr = 1e-3
    epochs = 50
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

    X_train = torch.tensor(df[[
        "Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos", "Weekday",
        "Sleep_duration", "Irregular_flag", "Awakenings",
        "Sleep_date_sin", "Sleep_date_cos", "Wake_date_sin","Wake_date_cos"
    ]].values, dtype=torch.float32).unsqueeze(0).to(device)
    Y_train = torch.tensor(df["alarm_strength"].values-1, dtype=torch.long).to(device)
    snooze = torch.tensor(df["snooze_count"].values, dtype=torch.float32).to(device)

    model = transferModel(transfer_input_size=12).to(device)
    ckpt = torch.load("AI/weight_pt/pretrained_model_full.pt", map_location=device)
    model.load_state_dict(ckpt)
    # 🔹 FeatureExtractor 고정 (Freeze)
    for param in model.feature_extractor.parameters():
        param.requires_grad = False
    for param in model.lstm.parameters():
        param.requires_grad = True
    for param in model.fc_out.parameters():
        param.requires_grad = True

    class_counts = Counter(df["alarm_strength"].values - 1)
    print("클래스 카운트:", class_counts)
    total = sum(class_counts.values())
    ratios = {c: count / total for c, count in class_counts.items()}
    ratio_threshold = 0.05

    mask = df["alarm_strength"].apply(lambda c: ratios[c-1] >= ratio_threshold).values
    mask = torch.tensor(mask, dtype=torch.bool).to(device)

    class_weights = []
    for c in range(4):
        r = ratios.get(c, 0)
        if ratios.get(c, 0) < ratio_threshold or class_counts.get(c, 0) == 0:
            class_weights.append(0.5)  # fine-tuning 영향 제거
        else:
            class_weights.append(total / class_counts[c])

    class_weights = torch.tensor(class_weights, dtype=torch.float32).to(device)

    criterion = nn.CrossEntropyLoss(weight=class_weights, reduction='none')
    optimizer = torch.optim.Adam([
        {"params": model.lstm.parameters(), "lr": 1e-4},  # LSTM 아주 약하게
        {"params": model.fc_out.parameters(), "lr": 1e-3},
    ])

    for epoch in range(epochs):
        model.train()
        optimizer.zero_grad()
        outputs = model(X_train)
        outputs = outputs.squeeze(0)
        loss = criterion(outputs, Y_train)
        loss = loss[mask]

        weights = 1.0 + 0.05 * (abs(snooze - 1.5)) - 0.2
        weights = weights[mask]
        weighted_loss = (loss * weights).mean()

        weighted_loss.backward()
        optimizer.step()

        if (epoch + 1) % 5 == 0:
            preds = torch.argmax(outputs, dim=1)
            acc = (preds[mask] == Y_train[mask]).float().mean()
            print(f"Epoch [{epoch + 1}/{epochs}] | Loss: {weighted_loss.item():.4f} | Acc: {acc.item():.4f}")

    torch.save(model.state_dict(), "AI/weight_pt/personalized_model.pt")
    print("✅ 전이학습 완료 및 모델 저장됨!")

#예측 + 보정 단계
def predict_with_correction(one_day_data, recent_success_mean):
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    model = transferModel().to(device)
    ckpt = torch.load("AI/weight_pt/pretrained_model_full.pt", map_location=device)
    model.load_state_dict(ckpt)
    model.load_state_dict(torch.load("AI/weight_pt/personalized_model.pt"))
    model.eval()

    x = one_day_data.unsqueeze(0).to(device)

    with torch.no_grad():
        output = model(x)
        output = output.squeeze(0)
        probs = torch.softmax(output, dim=1)
        pred_class = torch.argmax(probs, dim=1).item() + 1  # 1~4단계

        # ✅ 최근 7일 성공률로 보정
        if recent_success_mean < 0.5:
            pred_class = min(pred_class + 1, 4)

    print(f"🔔 보정된 알람 강도: {pred_class}단계 (성공률 {recent_success_mean:.2f})")
    return pred_class

if __name__ == "__main__":
    day_30_df = pd.read_csv("AI/csv/personal_30day.csv")
    train_transferModel(day_30_df)
    day_1_df = pd.read_csv("AI/csv/personal_oneday.csv")
    test_data = torch.tensor(day_1_df.values, dtype=torch.float32)
    print("test_data", test_data.shape)
    predict_with_correction(test_data, 0.52)

