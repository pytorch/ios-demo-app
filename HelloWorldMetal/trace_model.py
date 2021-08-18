import torch
import torchvision
from torch.utils.mobile_optimizer import optimize_for_mobile

model = torchvision.models.mobilenet_v2(pretrained=True)
scripted_model = torch.jit.script(model)
optimized_model = optimize_for_mobile(scripted_model, backend='metal')
print(torch.jit.export_opnames(optimized_model))
optimized_model._save_for_lite_interpreter('HelloWorldMetal/HelloWorldMetal/model/model.pt')