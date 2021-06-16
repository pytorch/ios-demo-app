import torch

model = torch.hub.load('pytorch/vision:v0.9.0', 'deeplabv3_resnet50', pretrained=True)
model.eval()

scripted_module = torch.jit.script(model)
scripted_module._save_for_lite_interpreter("ImageSegmentation/deeplabv3_scripted.ptl")
