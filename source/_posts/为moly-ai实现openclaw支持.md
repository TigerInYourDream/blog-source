---
title: 为moly-ai实现openclaw支持
date: 2026-02-04 20:14:38
tags:
 - open-claw
---

# 为moly-ai实现openclaw支持

Moly-ai [https://github.com/moly-ai/moly-ai] 是一个使用rust编写的LLM客户端，底层技术基于makepad。目前openclaw大火，并且支持大量主流的聊天工具接入。既然如此，自然也可以接入moly-ai.现在已经给原始的仓库提交了pr。这篇文章就用来描述：”如何为moly-ai实现openclaw支持“。

这篇文章将分为三个部分

1. 如何配置openclaw
2. 如何在moly-ai中配置使用openclaw
3. 为molyai支持openclaw的技术原理。

## 如何配置openclaw

Open claw 已经有非常详细的安装文档了https://docs.openclaw.ai/start/wizard 所有的细节均可以参考openclaw的官方文档。但我还是会带着大家过一遍你需要下面三个前置条件

1. 需要会阅读基本文档

2. 需要与准备好一个deepseek账号。

3. 需要通畅的网络

	

	下面是安装步骤

	1. 命令行安装

```
curl -fsSL https://openclaw.ai/install.sh | bash
```

2. 注意安装好之后会有一个风险提示，请选择同意
3. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.09.27%402x.png)
4. 然后会自然进入配置模式，选择第一个  QuickStart
5. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.13.01%402x.png)
6. 接下来进入到模型配置，因为我们要用deepseek, 所以选择skipall
7. 然后选择provider 供应商， 因为deepseek不再里面，随便选（跳过，后续再改）
8. ![CleanShot 2026-02-05 at 10.13.38@2x](/Users/zhaoyue/Library/Application Support/CleanShot/media/media_Ki2kJAqJ90/CleanShot 2026-02-05 at 10.13.38@2x.png)
9. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.15.40%402x.png)

9. 聊天软件配置，都是telegram discord之类的，我们继续跳过

10. skill包，和本地目标无关。继续跳过

11. Hooks配置。可以选一个mem，对于本次使用不重要
12. 然后就部署完成了。注意，我们的模型是随便选的，无法使用

13. 接下来验证 openclaw --version

然后进入最重要的配置阶段

```
openclaw config set 'models.providers.deepseek' --json '{
    "baseUrl": "https://api.deepseek.com/v1",
    "apiKey": "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "api": "openai-completions",
    "models": [
      { "id": "deepseek-chat", "name": "DeepSeek Chat" },
      { "id": "deepseek-reasoner", "name": "DeepSeek Reasoner" }
    ]
}'

openclaw config set models.mode merge

openclaw models set deepseek/deepseek-chat

openclaw gateway --port 18789 --verbose

// openclaw onboard --install-daemon

openclaw dashboard
```

上面是最重要的东西

14. 使用第一个命令 open claw config set 命令设置模型 provider key等。**注意你要换成自己的deepseek** **key**
15. 使用  openclaw config set models.mode merge  ， 设置models.mode 为merge
16. 使用 openclaw models set deepseek/deepseek-chat  设置模型，注意其实第一个已经设置过了，但是这里还是需要再次设置。没有为什么，截止2026/2/4 需要这样
17. 然后使用openclaw gateway --port 18789 --verbose  启动openclaw
18. 接下来使用 openclaw dashbord  会弹出网页。当然你要是第一次弹出是什么内容都没有的,chat 为空
19. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.23.22%402x.png)

20. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.24.34%402x.png)

dashbord后面会出现这个token是 很重要的

可以尝试和openclaw chat，查看是否配置正常。

## 如何配置moly-ai

因为molyai 还没有正式合并代码，请使用我的pr https://github.com/moly-ai/moly-ai/pull/630

如果不知道如何使用这个pr，请刚才配置好的openclaw来帮助你把代码拉倒本地。

molyai本身是需要使用rust的，要想体验这个功能需要提前安装rust工具链。你依然可以要求openclaw来帮助你安装rust工具链

接下来讲如何使用，一下操作的前提在于你已经安装好rust工具链，并且下载好了这个pr的代码。

1. 直接cargo run
2. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.34.09%402x.png)

3. 直接依次点击molyserver gotoproviders
4. ![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.35.58%402x.png)

5. 然后一次点击OpenClaw, 填入openclaw host, 它是一个websocket地址，这是openclaw的websocket端点，端口号为上一步设定的端口，18789 （如果你设定了其他端口，记得调整
6. 设定apikey, 严格来说它并不是apikey, 是openclaw给出的token. 记得填写“如何配置openclaw”章节最后openclaw dashbord给出的token
7. 依次打开4 5 处的开关代表启用。
8. 实际上ai是配置在openclaw中的
9. 注意看上面途中的1处，上面显示on,代表已经启用openclaw
10. 接下来开启聊天![](https://image-bucket-for-alvin.oss-cn-beijing.aliyuncs.com/blog/CleanShot%202026-02-05%20at%2010.43.50%402x.png)


## OpenClaw Gateway 集成技术原理

### 概述

以下介绍 Moly 应用与 OpenClaw Gateway 的集成实现，通过 WebSocket 协议将本地 AI 助手平台接入跨平台 Rust GUI 客户端。

### 什么是 OpenClaw？

OpenClaw 是一个本地 AI 助手平台，提供：
- 多渠道消息支持（WhatsApp、Telegram、Slack、Discord 等）
- 浏览器控制和自动化能力
- Canvas 工作区用于可视化输出
- 可扩展的技能系统
- 定时任务和 Webhooks
- 节点操作（摄像头、屏幕捕获等）

### 架构设计

#### 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    Moly 应用层                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Chat Screen (UI Layer)                 │ │
│  └──────────────────────┬─────────────────────────────┘ │
│                         │                                │
│  ┌──────────────────────▼─────────────────────────────┐ │
│  │         RouterClient (消息路由)                     │ │
│  └──────────────────────┬─────────────────────────────┘ │
│                         │                                │
│  ┌──────────────────────▼─────────────────────────────┐ │
│  │          MapClient (Bot ID 映射)                    │ │
│  └──────────────────────┬─────────────────────────────┘ │
│                         │                                │
│  ┌──────────────────────▼─────────────────────────────┐ │
│  │         OpenClawClient (BotClient trait)           │ │
│  │  • WebSocket 连接管理                               │ │
│  │  • 协议握手                                         │ │
│  │  • 流式响应处理                                     │ │
│  └──────────────────────┬─────────────────────────────┘ │
└─────────────────────────┼───────────────────────────────┘
                          │ WebSocket (ws://127.0.0.1:18789)
                          │
┌─────────────────────────▼───────────────────────────────┐
│              OpenClaw Gateway (本地服务)                 │
│  • Agent 处理                                            │
│  • 工具执行                                              │
│  • 多渠道协调                                            │
└──────────────────────────────────────────────────────────┘
```

#### 与 Moly/MolyKit/AITK 的集成

| 层级 | 职责 |
|------|------|
| **AITK** | 核心协议层，定义 `BotClient` trait、通用类型（Bot、Message、MessageContent）、跨平台异步工具 |
| **MolyKit** | 可复用 UI 组件，聊天 Widget、消息渲染、模型选择器 |
| **Moly App** | 主应用，实现特定 Provider 客户端，管理配置和路由 |

### 协议实现

#### OpenClaw 协议流程

```
Client                          Gateway
  │                                │
  ├─── connect request ───────────>│
  │    (auth token, protocol v3)   │
  │                                │
  │<──── connect.challenge ────────┤ (可选，远程模式)
  │                                │
  ├─── connect request ───────────>│ (重新发送带认证)
  │                                │
  │<──── hello-ok response ────────┤
  │                                │
  ├─── agent request ─────────────>│
  │    (message + history)         │
  │                                │
  │<──── agent.text.delta ─────────┤ (流式响应)
  │<──── agent.text.delta ─────────┤
  │<──── agent.text.delta ─────────┤
  │         ...                    │
  │                                │
  │<──── chat (state: done) ───────┤ (完成信号)
  │                                │
```

#### 消息类型

| 类型 | 方向 | 说明 |
|------|------|------|
| `req` | Client → Gateway | 请求消息（connect、agent） |
| `res` | Gateway → Client | 响应消息（hello-ok、agent 完成） |
| `event` | Gateway → Client | 事件消息（流式文本、状态变更） |

#### 请求结构

```rust
struct Request<T> {
    r#type: &'static str,  // "req"
    id: String,            // UUID v4
    method: String,        // "connect" | "agent"
    params: T,             // 方法特定参数
}
```

**Connect 参数：**
```rust
struct ConnectParams {
    min_protocol: u32,           // 3
    max_protocol: u32,           // 3
    role: &'static str,          // "operator"
    scopes: Vec<&'static str>,   // ["operator.read", "operator.write"]
    client: ClientInfo,
    auth: Option<AuthInfo>,      // 可选认证 token
}
```

**Agent 参数：**
```rust
struct AgentParams {
    message: String,             // 用户消息 + 历史
    idempotency_key: String,     // UUID v4 防重复
    agent_id: &'static str,      // "main"
}
```

### 核心实现

#### BotClient Trait 实现

`OpenClawClient` 实现了 AITK 定义的 `BotClient` trait：

```rust
impl BotClient for OpenClawClient {
    // 返回可用的 Bot 列表
    fn bots(&mut self) -> BoxPlatformSendFuture<'static, ClientResult<Vec<Bot>>>;

    // 发送消息并返回流式响应
    fn send(
        &mut self,
        bot_id: &BotId,
        messages: &[Message],
        tools: &[Tool],
    ) -> BoxPlatformSendStream<'static, ClientResult<MessageContent>>;

    // 克隆客户端
    fn clone_box(&self) -> Box<dyn BotClient>;
}
```

#### 流式响应处理

使用 `async_stream` 宏实现异步流：

```rust
let stream = stream! {
    // 1. 建立 WebSocket 连接
    let (ws_stream, _) = connect_async(&inner.url).await?;
    let (mut write, read) = ws_stream.split();

    // 2. 发送 connect 请求
    write.send(WsMessage::Text(connect_json)).await?;

    // 3. 处理消息循环
    loop {
        match read.next().await {
            // 处理事件和响应
            // yield 流式内容给 UI
        }
    }
};
```

#### 事件处理状态机

```rust
enum ProcessResult {
    Continue,              // 继续等待
    Yield(MessageContent), // 输出内容到 UI
    Error(ClientError),    // 错误终止
    SendConnect,           // 发送连接请求
    SendAgent,             // 发送 agent 请求
    Done,                  // 完成
}
```

#### 文本去重算法

OpenClaw 可能发送重叠的文本片段，需要智能合并：

```rust
fn merge_text_content(content: &mut String, incoming: &str) {
    // 1. 空内容直接追加
    // 2. incoming 包含 content → 替换
    // 3. content 包含 incoming → 忽略
    // 4. 查找重叠部分 → 只追加新内容
}

fn find_overlap_bytes(content: &str, incoming: &str) -> usize {
    // 基于字符边界的重叠检测
    // 支持 UTF-8 多字节字符
}
```

### 跨平台支持

#### 平台差异处理

| 平台 | WebSocket 库 | 异步运行时 |
|------|-------------|-----------|
| Desktop (macOS/Windows/Linux) | `tokio-tungstenite` | Tokio |
| Web (WASM) | 不支持 | wasm-bindgen |

```rust
#[cfg(not(target_arch = "wasm32"))]
fn send(...) -> BoxPlatformSendStream<...> {
    // 完整 WebSocket 实现
}

#[cfg(target_arch = "wasm32")]
fn send(...) -> BoxPlatformSendStream<...> {
    // 返回友好提示，引导用户使用桌面版或 Web UI
}
```

#### 历史消息限制

为防止请求过大，限制历史消息数量：

```rust
const MAX_HISTORY_MESSAGES: usize = 32;

fn build_history_message(messages: &[Message]) -> String {
    let start = messages.len().saturating_sub(MAX_HISTORY_MESSAGES);
    // 格式化为 "role: content" 形式
}
```

### 错误处理

#### 错误类型

```rust
enum ClientErrorKind {
    Network,   // 网络连接错误
    Format,    // 序列化/反序列化错误
    Response,  // Gateway 返回错误
    Unknown,   // 未知错误
}
```

#### 超时处理

```rust
const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(10);

// 使用 futures::select! 实现超时
futures::select! {
    _ = handshake_deadline => {
        if !connected {
            yield ClientError::new(ClientErrorKind::Network, "Timed out...");
        }
    }
    msg = read.next() => { /* 处理消息 */ }
}
```

### 文件变更清单

| 文件 | 变更类型 | 说明 |
|------|---------|------|
| `src/data/openclaw_client.rs` | 新增 | 核心客户端实现 (613 行) |
| `src/data/mod.rs` | 修改 | 添加模块导出 |
| `src/data/providers.rs` | 修改 | 添加 `OpenClaw` 枚举变体 |
| `src/data/supported_providers.json` | 修改 | 添加 Provider 配置 |
| `src/data/bot_fetcher.rs` | 修改 | 添加客户端工厂逻辑 |
| `src/chat/chat_screen.rs` | 修改 | 添加 UI 路由 |
| `Cargo.toml` | 修改 | 添加 `tokio-tungstenite` 依赖 |

### 依赖项

```toml
[dependencies]
tokio-tungstenite = "0.26"  # WebSocket 客户端
uuid = { version = "1", features = ["v4"] }  # 请求 ID 生成
async-stream = "0.3"  # 异步流宏
futures = "0.3"  # 异步原语
```

### 总结

OpenClaw 集成的核心设计原则：

1. **Trait 抽象**：通过实现 `BotClient` trait 无缝接入现有架构
2. **流式处理**：使用 async stream 实现实时响应展示
3. **跨平台兼容**：通过条件编译处理平台差异
4. **健壮性**：完善的错误处理、超时机制、文本去重
5. **可配置**：通过 JSON 配置文件管理 Provider 信息

