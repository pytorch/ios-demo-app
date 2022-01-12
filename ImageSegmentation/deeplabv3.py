import torch
from torch.utils.mobile_optimizer import optimize_for_mobile

model = torch.hub.load('pytorch/vision:v0.11.0', 'deeplabv3_resnet50', pretrained=True)
model.eval()

scripted_module = torch.jit.script(model)
optimized_model = optimize_for_mobile(scripted_module)
optimized_model.save("ImageSegmentation/deeplabv3_scripted.pt")
optimized_model._save_for_lite_interpreter("ImageSegmentation/deeplabv3_scripted.ptl")
