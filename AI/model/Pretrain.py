import torch
import torch.nn as nn
import torch.optim as optim
import pandas as pd
from torch.utils.data import TensorDataset, DataLoader
from sklearn.utils.class_weight import compute_class_weight
import numpy as np
import os

# 특징 추출기
class FeatureExtractor(nn.Module):
    def __init__(self, input_size, embedding_size=32):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(input_size, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(128, embedding_size),
            nn.BatchNorm1d(embedding_size),
            nn.ReLU()
        )

    def forward(self, x):
        return self.net(x)

class PretrainTransferModel(nn.Module):
    def __init__(self, pretrain_input_size=12,
                 embedding_size=32, hidden_size=64, num_classes=4):
        super().__init__()
        self.feature_extractor = FeatureExtractor(pretrain_input_size, embedding_size)
        self.lstm = nn.LSTM(embedding_size, hidden_size, batch_first=True)
        self.fc_out = nn.Linear(hidden_size, num_classes)

    def forward(self, x_seq):
        # x_seq: (B, seq_len, feature)
        batch, seq_len, _ = x_seq.shape

        # seq_len == 1 이므로 그냥 batch, feature 로 reshape
        x_seq = x_seq.reshape(batch * seq_len, -1)

        # FeatureExtractor
        z = self.feature_extractor(x_seq)

        # 다시 LSTM 입력 형태로 reshape => (B, 1, embedding)
        z = z.view(batch, seq_len, -1)

        # LSTM
        lstm_out, _ = self.lstm(z)

        # 마지막 timestep만 사용 (seq_len=1이므로 lstm_out[:, -1, :])
        out = self.fc_out(lstm_out[:, -1, :])
        return out


def playing():
    input_size = 12  # ✔ 최종 feature 수
    embedding_size = 32
    hidden_size = 64
    num_classes = 4
    lr = 1e-3
    epochs = 50

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

    # ----------------------------------------
    # 1) 데이터 로드
    # ----------------------------------------
    df = pd.read_csv("AI/csv/pretrain_dataset.csv")

    feature_cols = [
        "Bed_sin", "Bed_cos",
        "Wake_sin", "Wake_cos",
        "Awakenings", "Sleep_duration",
        "Irregular_flag",
        "Sleep_date_sin", "Sleep_date_cos",
        "Wake_date_sin", "Wake_date_cos",
        "Weekday"
    ]

    X_train = torch.tensor(df[feature_cols].values, dtype=torch.float32)
    Y_train = torch.tensor(df["alarm_strength"].values - 1, dtype=torch.long)

    X_train = X_train.to(device)
    Y_train = Y_train.to(device)

    # ----------------------------------------
    # 2) 클래스 가중치 계산
    # ----------------------------------------
    classes = np.array([0, 1, 2, 3], dtype=np.int64)

    class_weights = compute_class_weight(
        class_weight="balanced",
        classes=classes,
        y=Y_train.cpu().numpy()
    )

    class_weights = torch.tensor(class_weights, dtype=torch.float32).to(device)

    # ----------------------------------------
    # 3) DataLoader
    # ----------------------------------------
    dataset = TensorDataset(X_train, Y_train)
    loader = DataLoader(dataset, batch_size=64, shuffle=True)

    # ----------------------------------------
    # 4) 모델 생성
    # ----------------------------------------
    model = PretrainTransferModel(
        pretrain_input_size=input_size,
        embedding_size=embedding_size,
        hidden_size=hidden_size,
        num_classes=num_classes
    ).to(device)

    criterion = nn.CrossEntropyLoss(weight=class_weights)
    optimizer = optim.Adam(model.parameters(), lr=lr)

    # ----------------------------------------
    # 5) 학습
    # ----------------------------------------
    for epoch in range(epochs):
        model.train()
        total_loss = 0
        total_acc = 0
        count = 0

        for X_batch, Y_batch in loader:
            X_batch = X_batch.to(device).unsqueeze(1)  # (B, 1, feature)
            Y_batch = Y_batch.to(device)

            optimizer.zero_grad()
            logits = model(X_batch)

            loss = criterion(logits, Y_batch)
            loss.backward()
            optimizer.step()

            preds = torch.argmax(logits, dim=1)
            total_loss += loss.item() * len(X_batch)
            total_acc += (preds == Y_batch).float().sum().item()
            count += len(X_batch)

        if (epoch + 1) % 5 == 0:
            print(f"Epoch {epoch + 1}/{epochs}  Loss: {total_loss / count:.4f}  Acc: {total_acc / count:.4f}")

    # ----------------------------------------
    # 6) 가중치 저장
    # ----------------------------------------
    os.makedirs("models", exist_ok=True)

    torch.save(model.state_dict(), "AI/weight_pt/pretrained_model_full.pt")

    print("✔ Pretrain 완성!  pretrained_model_full.pt 저장됨.")


if __name__ == "__main__":
    playing()
