# AudioContinuousTaskManager

## 项目简介
`AudioContinuousTaskManager` 是一个基于 `HarmonyOS` 的音频后台播放管理工具，支持后台音频播放、AVSession 管理、长时任务启动等功能。

## 特性
- **单例模式**：确保 `AudioContinuousTaskManager` 仅有一个实例。
- **AVSession 支持**：支持音频后台播放状态管理。
- **长时任务**：集成 `BackgroundTasksKit` 以支持音频后台运行。
- **事件通知**：提供 `EventHub` 事件通知机制，外部可以监听播放、暂停等事件。

---

## 平台

```
环境要求
HarmonyOS SDK
DevEco Studio
```

---

## 使用方法

### 1. 启动长时任务
```typescript
import AudioContinuousTaskManager from './AudioContinuousTaskManager';

const context = getContext(this);
AudioContinuousTaskManager.startContinuousTask(context, '示例音频', 300);
```

### 2. 停止长时任务
```typescript
AudioContinuousTaskManager.stopContinuousTask(context);
```

### 3. 监听音频事件
```typescript
const eventHub = getContext(this).eventHub;
eventHub.on(AUDIO_BACK_SESSION_EVENT_KEY, (event) => {
  console.log('音频事件：', event);
});
```

---

## API 说明

### `startContinuousTask(uiContext: Context, title: string, duration: number): Promise<void>`
启动音频后台播放的长时任务。
- `uiContext`：应用上下文。
- `title`：音频标题。
- `duration`：音频时长（秒）。

### `stopContinuousTask(uiContext: Context): Promise<void>`
停止音频后台播放任务。

### `createAVSession(title: string, duration: number): Promise<void>`
创建 `AVSession` 并初始化播放状态。
- `title`：媒体标题。
- `duration`：媒体时长。

### `setAVPlaybackState(): Promise<void>`
更新 `AVSession` 的播放状态。

### `unregisterSessionListener(): void`
注销 `AVSession` 监听器并释放资源。

### `emitEvent(eventKey: string, event: AUDIO_BACK_SESSION_EVENT | AUDIO_CONTINUOUS_COMPELETE_EVENT, data?: number): void`
触发自定义事件。

---

## 事件列表

| 事件 | 描述 |
|------|------|
| `AUDIO_BACK_SESSION_EVENT_PLAY` | 播放 |
| `AUDIO_BACK_SESSION_EVENT_PAUSE` | 暂停 |
| `AUDIO_BACK_SESSION_EVENT_FASTFORWARD` | 快进 |
| `AUDIO_BACK_SESSION_EVENT_REWIND` | 快退 |
| `AUDIO_BACK_SESSION_EVENT_SEEK` | 跳转 |
| `CONTINUOUS_COMPELETE_SUCCESS` | 任务成功 |
| `CONTINUOUS_COMPELETE_ERROR` | 任务失败 |

---

## 贡献
欢迎提交 issue 或 PR，改进该项目！

---

## 许可证
MIT License
