import torch
import torch.nn as nn
import torchvision.models as models
from torchvision.models import shufflenet_v2_x1_0
class LightCDC(nn.Module):
    def __init__(self, num_classes=2, dropout=0.5):
        super(LightCDC, self).__init__()

        # ShuffleNetV2 x1.0 backbone — pretrained on ImageNet
        backbone = shufflenet_v2_x1_0(weights="IMAGENET1K_V1")

        # Remove the original classifier
        # ShuffleNetV2 x1.0 outputs 1024 features before fc
        self.features = nn.Sequential(
            backbone.conv1,
            backbone.maxpool,
            backbone.stage2,
            backbone.stage3,
            backbone.stage4,
            backbone.conv5,
        )

        self.pool = nn.AdaptiveAvgPool2d((1, 1))

        # Custom classifier — exactly as in the paper
        self.classifier = nn.Sequential(
            nn.Linear(1024, 512),
            nn.ReLU(inplace=True),
            nn.Dropout(p=dropout),
            nn.Linear(512, 512),
            nn.ReLU(inplace=True),
            nn.BatchNorm1d(512),
            nn.Linear(512, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        x = self.pool(x)
        x = torch.flatten(x, 1)
        x = self.classifier(x)
        return x
