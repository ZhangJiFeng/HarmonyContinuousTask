# AudioContinuousTaskManager

## 项目简介
`AudioContinuousTaskManager` 是一个基于 `HarmonyOS` 的音频后台播放管理工具，支持后台音频播放、AVSession 管理、长时任务启动等功能。

## 特性
- **单例模式**：确保 `AudioContinuousTaskManager` 仅有一个实例。
- **AVSession 支持**：支持音频后台播放状态管理。
- **长时任务**：集成 `BackgroundTasksKit` 以支持音频后台运行。
- **事件通知**：提供 `EventHub` 事件通知机制，外部可以监听播放、暂停等事件。

---

## 环境要求

```
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
  console.log('与自身音视频业务进行交互');
});
```
### 4. 通知后台音频通知变更
``` typescript
this.currentState.position = {
        state: AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY,
        elapsedTime: position,
        updateTime: new Date().getTime()
    };
this.session?.setAVPlaybackState(this.currentState);
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

## 注意事项
约束与限制
申请限制：Stage模型中，长时任务仅支持UIAbility申请；FA模型中，长时任务仅支持ServiceAbility申请。长时任务支持设备当前应用申请，也支持跨设备或跨应用申请，跨设备或跨应用仅对系统应用开放。

数量限制：一个UIAbility(FA模型则为ServiceAbility)同一时刻仅支持申请一个长时任务，即在一个长时任务结束后才可能继续申请。如果一个应用同时需要申请多个长时任务，需要创建多个UIAbility;一个应用的一个UIAbility申请长时任务后，整个应用下的所有进程均不会被挂起。

---

## 贡献
欢迎提交 issue 或 PR，改进该项目！

---

## 许可证
MIT License
