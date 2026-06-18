import torch
import torch.nn as nn
import brevitas.nn as qnn
from brevitas.export import export_qonnx

class ToyQNN(nn.Module):
    def __init__(self):
        super().__init__()

        self.fc1 = qnn.QuantLinear(
            16, 8,
            bias=False,
            weight_bit_width=4
        )

        self.act = qnn.QuantReLU(
            bit_width=4
        )

        self.fc2 = qnn.QuantLinear(
            8, 4,
            bias=False,
            weight_bit_width=4
        )

    def forward(self, x):
        return self.fc2(self.act(self.fc1(x)))

model = ToyQNN().eval()

dummy = torch.zeros(1, 16)

export_qonnx(
    model,
    dummy,
    "toy_model.onnx"
)

print("Exported: toy_model.onnx")
