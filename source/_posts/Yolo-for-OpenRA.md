---
title: Yolo for OpenRA
abbrlink: 46137
date: 2025-09-01 10:51:58
tags: yolo
---

# YOLO for OpenRA

本文讲如何使用 yolo 识别 openra中的物体。

## 什么是 yolo?

实际情况是我也不懂。具体参考 https://www.ultralytics.com/.   大概是深度学习和计算机视觉相关的库。

## 阅读文章的起点

阅读文章的起点指的是一下两个问题

* 为什么要用 yolo来识别 OpenRA中的物体
* 在做yolo识别的时候相关的知识储备是什么样的

需要反着回答，知识储备是什么都不懂，一不明白什么是计算机视觉，而是不明白 python。不过不用担心，python比较简单，不会也可以看懂代码。

做 yolo识别是因为最近 GOSIM2015 有一个 hackthon，组委会提供了一个魔改的 OpenRA, 可以使用 socket来和 OpenRA交互。使用 api来驱动 openra中的单位来进行建设，探索，作战。组委会的目的应该是探索 LLM的应用，Agent的开发。我看到很多参赛选手做了非常高级的 agent可以打字和 llm沟通，进行建设，探图和摧毁敌方目标。不过这种模式是类似于我对 mcp的理解，我自己的思路是把所有的 API做成 mcp的 function. 语音和 llm交互的时候，llm决定去调用哪一类的 function完成任务。我更偏好全自动作战，不要人的参与就可以完成所有的目标，所以我想引入 YOLO来识别游戏中目标，让 agent自动规划需要怎么做。

注意使用 yolo其实并不符合 hackthon的目标，因为没什么必要。大会的OpenRA提供战争迷雾和 query类别的 api.合理使用 api就可以做到感知游戏状态和信息。这里使用 yolo主要是为了有趣，并且想实现在没有 API支持的情况下，也可以尝试自动完成对战（当然键盘和鼠标的模拟会很繁琐）。

## yolo小知识

这里需要知道一个 yolo的小知识，迁移训练：迁移训练指的是 yolo本身有大概五十个目标识别的模型，现在让 yolo忘记自己本来认识的 五十个目标，重新学习 10 个和红色警戒有关的目标。这就是迁移训练（学习）。

## 三个步骤

使用 yolo来识别红色警戒的目标需要三个步骤，就像把大象塞进冰箱需要三步一样

* dataset的准备
* 迁移训练
* 识别

训练需要先进行数据的准备，这一部肯定是整个过程中最麻烦的一部。有很多标注用的工具，但是我们用无敌的 https://roboflow.com/ 

labelimg也可以。

### 数据集的准备

先打开录制，然后开一局红色警戒录下来。需要吐槽的是现在openra的字体相当小，打一局非常费眼睛对身体不利，为了身体健康引入 yolo是很有必要的，人最好一点不看就能打败对手是最好的。

注意录制好的录像可以使用 handbrake压制一下，不然太大，而且 OPENRA分辨率相当低，压缩到很小就行，不是高清 4k游戏没必要。一局最好只选 1 个敌人，在 15 分钟之内 rush搞定。这样数据比较小，对身体也好。

然后把压制好的数据上传到 roboflow, roboflow可以把视频裁成一帧一帧的图片。为了身体健康，最好少一点数据大概一百五十张差不多了。然后开始无敌的标注，注意标注数据不要太粗心大意，尽量贴合好目标的边框不要超出物体本身，否则会影响训练结果。实际上是 rush局，单位也不会特别多，标注个 50 来张差不多了，很累。当然数据是越多越好，只是在这里没必要，浪费眼睛耐久度。

标注好数据后把数据分成三个数据集

* train
* test
* valid

训练集，验证集，测试集。大概 6:3:1 的比例即可。图片多可以稍微调一调比例。和平息考试一个道理，多训练。所以训练集最多。做好数据集之后，从 roboflow 下载回来。此时很可能已经花费了数个小时。数据标注真的苦工😭

### 训练准备

准备好数据集之后就可以开始训练了。阅读 https://docs.ultralytics.com/zh/quickstart/

可以启动一个 python的虚拟环境, 我们使用 uv

```
uv venv
source .venv/bin/activate

# Install other core dependencies
uv pip install torch torchvision numpy matplotlib polars pyyaml pillow psutil requests scipy seaborn ultralytics-thop

# Install headless OpenCV instead of the default
uv pip install opencv-python-headless
```

注意启动虚拟环境 并且激活他 然后再 uv中安装这些必要的依赖，这个可以在 ultralytics的手动安装中找到。理论上来说，使用 docker是最好的方案，但是我的电脑是 mac的 docker无法使用mps加速 

具体可以看 

https://docs.ultralytics.com/modes/train/#idle-gpu-training

yolo训练使用起来非常简单

实例代码是这样的

```
from ultralytics import YOLO

# Load a model
model = YOLO("yolo11n.pt")  # load a pretrained model (recommended for training)

# Train the model with 2 GPUs
results = model.train(data="coco8.yaml", epochs=100, imgsz=640, device=[0, 1])

# Train the model with the two most idle GPUs
results = model.train(data="coco8.yaml", epochs=100, imgsz=640, device=[-1, -1])
```

主要有三部分 加载模型 加载数据集 然后开始训练。我们的模型是 v8n，配置的 yaml参数甚至是 roboflow给好的。我会在后面列出 github的地址。

```
just train 
```

因为数据比较简单在我的 m2mx 上，使用 mps加速，训练 200 轮大概也就 14 分钟。

```
      Epoch    GPU_mem   box_loss   cls_loss   dfl_loss  Instances       Size
    198/200      2.27G      0.521     0.4953     0.8555         13        640: 100% ━━━━━━━━━━━━ 6/6 2.6it/s 2.3s
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95): 100% ━━━━━━━━━━━━ 1/1 2.0it/s 0.5s
                   all          8         60      0.982      0.981      0.977       0.91

      Epoch    GPU_mem   box_loss   cls_loss   dfl_loss  Instances       Size
    199/200      2.28G     0.5229      0.558     0.8557          8        640: 100% ━━━━━━━━━━━━ 6/6 2.8it/s 2.2s
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95): 100% ━━━━━━━━━━━━ 1/1 6.7it/s 0.1s
                   all          8         60      0.982      0.981      0.977       0.91



```

训练起来大概就是上面的样式

```
Validating runs/red-alert_20250901_001914/weights/best.pt...
Ultralytics 8.3.190 🚀 Python-3.13.5 torch-2.8.0 MPS (Apple M2 Max)
Model summary (fused): 72 layers, 3,007,013 parameters, 0 gradients, 8.1 GFLOPs
                 Class     Images  Instances      Box(P          R      mAP50  mAP50-95): 100% ━━━━━━━━━━━━ 1/1 0.31it/s 3.2s
                   all          8         60      0.984      0.981      0.977      0.911
              bingying          6          6      0.993          1      0.995      0.874
             dianchang          8         27      0.995          1      0.995      0.895
                  jidi          8          9      0.982      0.889      0.888      0.844
          jungongchang          6          6      0.974          1      0.995      0.995
            kuangchang          6          6      0.976          1      0.995      0.912
                 leida          6          6      0.986          1      0.995      0.944
Speed: 0.4ms preprocess, 95.0ms inference, 0.0ms loss, 67.5ms postprocess per image
Results saved to runs/red-alert_20250901_001914
✅ 训练完成！
⏱️ 用时: 0小时 14分钟 49秒
💾 模型保存位置: runs/red-alert_20250901_001914/weights/
📊 最佳模型: runs/red-alert_20250901_001914/weights/best.pt
📈 TensorBoard: tensorboard --logdir runs

```

结果就是这样的

### 识别

识别也参考文档即可  如果觉得麻烦 可以直接在目录下

```
yolo predict model=runs/red-alert_20250901_001914/weights/best.pt source=/Users/xxx/Desktop/openra.mp4 show=true conf=0.25
```

如果不行  注意路径。实际效果如下

![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/img/Xnip%20Helper%202025-09-01%2010.31.09.png)



也就三步，就可以识别出 OpenRA中的物体了。
