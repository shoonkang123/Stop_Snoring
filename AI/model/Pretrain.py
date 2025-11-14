import torch
import torch.nn as nn
import torch.optim as optim
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
import joblib

#특징 추출기
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

class PretrainModel(nn.Module):
    def __init__(self, input_size, embedding_size=32, num_classes=4):
        super().__init__()
        self.feature_extractor = FeatureExtractor(input_size, embedding_size)
        self.fc_out = nn.Linear(embedding_size, num_classes)

    def forward(self, x):
        z = self.feature_extractor(x)
        logits = self.fc_out(z)
        return logits

def playing():
    input_size = 8
    embedding_size = 32
    num_classes = 4
    lr = 1e-3
    epochs = 50
    df = pd.read_csv("csv/final_2200_delete_sleep_data.csv")

    X_train = torch.tensor(df[["Bed_sin", "Bed_cos", "Wake_sin", "Wake_cos", "Awakenings",
                           "Sleep_duration", "Irregular_flag", "snooze_count"]].values,
                           dtype=torch.float32)
    Y_train = torch.tensor(df["alarm_strength"].values-1, dtype=torch.long)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    X_train = X_train.to(device)
    Y_train = Y_train.to(device)

    model = PretrainModel(input_size, embedding_size, num_classes).to(device)
    criterion = nn.CrossEntropyLoss() #다중 클래스 분류용 손실함수
    optimizer = optim.Adam(model.parameters(), lr=lr)

    for epoch in range(epochs):
        model.train()
        optimizer.zero_grad()

        logits = model(X_train)
        loss = criterion(logits, Y_train)
        loss.backward()
        optimizer.step()

        if (epoch + 1) % 5 == 0:
            preds = torch.argmax(logits, dim=1)
            acc = (preds == Y_train).float().mean()
            print(f"Epoch [{epoch + 1}/{epochs}] | Loss: {loss.item():.4f} | Acc: {acc.item():.4f}")

    torch.save(model.feature_extractor.state_dict(), "models/feature_extractor_real_pretrained_batchnorm.pt")

if __name__ == "__main__":
    playing()