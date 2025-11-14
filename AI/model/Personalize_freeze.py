import pandas as pd
import torch
import torch.nn as nn
import torch.optim as optim
from .Pretrain import FeatureExtractor

class transferModel(nn.Module):
    def __init__(self, transfer_input_size=12, pretrain_input_size = 8,
                 embedding_size=32, hidden_size=64, num_classes=4):
        super().__init__()
        self.adapter = nn.Sequential(
            nn.Linear(transfer_input_size, pretrain_input_size),
            nn.ReLU()
        )
        self.feature_extractor = FeatureExtractor(pretrain_input_size, embedding_size)
        self.lstm = nn.LSTM(embedding_size, hidden_size, batch_first=True)
        self.fc_out = nn.Linear(hidden_size, num_classes)

    def forward(self, x_seq):
        batch, seq_len, _ = x_seq.shape
        x_seq = x_seq.reshape(batch * seq_len, -1)
        x = self.adapter(x_seq)
        z = self.feature_extractor(x)
        z = z.view(batch, seq_len, -1)
        lstm_out, _ = self.lstm(z)
        out = self.fc_out(lstm_out)
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
    pretrain_dict = torch.load("models/feature_extractor_real_pretrained_batchnorm.pt")
    model.feature_extractor.load_state_dict(pretrain_dict)
    # 🔹 FeatureExtractor 고정 (Freeze)
    for param in model.feature_extractor.parameters():
        param.requires_grad = False

    criterion = nn.CrossEntropyLoss()  # 다중 클래스 분류용 손실함수
    optimizer = torch.optim.Adam(
        filter(lambda p: p.requires_grad, model.parameters()),
        lr=lr
    )

    for epoch in range(epochs):
        model.train()
        optimizer.zero_grad()
        print("Y_train",Y_train.shape)
        outputs = model(X_train)
        print("outputs",outputs.shape)
        outputs = outputs.squeeze(0)
        loss = criterion(outputs, Y_train)

        #알람 성공을 실패 했을 때 가중치를 더 줌
        alpha = 0.4
        weights = 1.0 + alpha * (abs(snooze - 1.5)) - 0.2
        weighted_loss = (loss * weights).mean()

        weighted_loss.backward()
        optimizer.step()

        if (epoch + 1) % 5 == 0:
            preds = torch.argmax(outputs, dim=1)
            acc = (preds == Y_train).float().mean()
            print(f"Epoch [{epoch + 1}/{epochs}] | Loss: {weighted_loss.item():.4f} | Acc: {acc.item():.4f}")
    # 추후 저장 경로를 수정해줘야 함
    torch.save(model.state_dict(), "models/Pretrain_lstm_snooze_User.pt")

#예측 + 보정 단계
def predict_with_correction(one_day_data, recent_success_mean):
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    model = transferModel().to(device)
    pretrain_dict = torch.load("models/feature_extractor_real_pretrained_batchnorm.pt")
    model.feature_extractor.load_state_dict(pretrain_dict)
    model.load_state_dict(torch.load("models/Pretrain_lstm_snooze_Irregular.pt"))
    model.eval()

    x = torch.tensor(one_day_data, dtype=torch.float32).unsqueeze(0).to(device)

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
    day_30_df = pd.read_csv("csv/Irregular_personal_30day.csv")
    # train_transferModel(day_30_df)
    day_1_df = pd.read_csv("csv/Irregular_personal_oneday.csv")
    test_data = torch.tensor(day_1_df.values, dtype=torch.float32)
    print("test_data", test_data.shape)
    predict_with_correction(test_data, 0.52)
