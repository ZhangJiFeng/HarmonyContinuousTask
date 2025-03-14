import { wantAgent } from '@kit.AbilityKit';
import { avSession as AVSessionManager } from '@kit.AVSessionKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';

const TAG = '[AudioContinuousTaskManager]'

// 外部业务task感知
export const AUDIO_CONTINUOUS_COMPELETE_EVENT_KEY = 'audioContinuousTaskCompeleteStatus';
export enum AUDIO_CONTINUOUS_COMPELETE_EVENT {
  CONTINUOUS_COMPELETE_SUCCESS,
  CONTINUOUS_COMPELETE_ERROR,
}

// 后台音频通知event感知
export const AUDIO_BACK_SESSION_EVENT_KEY = 'audioBackSessionStatus';
export enum AUDIO_BACK_SESSION_EVENT {
  AUDIO_BACK_SESSION_EVENT_PLAY,
  AUDIO_BACK_SESSION_EVENT_PAUSE,
  AUDIO_BACK_SESSION_EVENT_FASTFORWARD,
  AUDIO_BACK_SESSION_EVENT_REWIND,
  AUDIO_BACK_SESSION_EVENT_SEEK
}


class AudioContinuousTaskManager {
  private static instance: AudioContinuousTaskManager;
  private session: AVSessionManager.AVSession | null = null;
  public audioMode: boolean = false;

  public currentState: AVSessionManager.AVPlaybackState = {
    state: AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY
  };

  // 记录音视频长时任务task注册状态
  public audioModeStartContinuousTaskCompleteSucceeded: boolean = false;
  public audioModeStartContinuousTaskCompleteError: boolean = false;

  private constructor() {
    // 私有构造函数，防止外部实例化
  }

  /** 获取单例实例 */
  public static getInstance(): AudioContinuousTaskManager {
    if (!AudioContinuousTaskManager.instance) {
      AudioContinuousTaskManager.instance = new AudioContinuousTaskManager();
    }
    return AudioContinuousTaskManager.instance;
  }

  /**
   * 创建AVSession
   * @param title 媒体标题
   * @param duration 媒体时长
   */
  public async createAVSession(title: string, duration: number) {
    // 假设已经创建了一个session，如何创建session可以参考之前的案例
    this.session = await AVSessionManager.createAVSession(getContext(this), 'SESSION_NAME', 'video');
    // 设置必要的媒体信息
    let metadata: AVSessionManager.AVMetadata = {
      assetId: 'xxxxxx', // 由应用指定，用于标识应用媒体库里的媒体
      title: title || '音频',
      mediaImage: 'IMAGE',
      artist: '音频后台播放',
      duration: duration,
    };
    this.session?.setAVMetadata(metadata).then(() => {
      console.debug(TAG, `SetAVMetadata successfully`);
    }).catch((err: BusinessError) => {
      console.debug(TAG, `Failed to set AVMetadata. Code: ${err.code}, message: ${err.message}`);
    });

    // 注册后台通知UI及回调相关
    this.registerSessionListener();
    await this.session?.activate().catch((err: BusinessError) => {
      if (err) {
        console.debug(TAG, `Failed to activate AVSession, error info: ${JSON.stringify(err)}`);
      }
    });

    await this.session?.setAVPlaybackState(this.currentState);
  }

  /**
   * 设置AVPlaybackState
   */
  public async setAVPlaybackState() {
    await this.session?.setAVPlaybackState(this.currentState);
  }

  /**
   * 注册Session监听器
   */
  private registerSessionListener() {
    // 播放
    this.session?.on('play', async () => {
      console.debug(TAG, `on play, do play task`);

      this.emitEvent(AUDIO_BACK_SESSION_EVENT_KEY, AUDIO_BACK_SESSION_EVENT.AUDIO_BACK_SESSION_EVENT_PLAY);
      this.currentState = {
        state: AVSessionManager.PlaybackState.PLAYBACK_STATE_PLAY
      };
      await this.session?.setAVPlaybackState(this.currentState);
    });

    // 暂停
    this.session?.on('pause', async () => {
      console.debug(TAG, `on pause, do pause task`);

      this.emitEvent(AUDIO_BACK_SESSION_EVENT_KEY, AUDIO_BACK_SESSION_EVENT.AUDIO_BACK_SESSION_EVENT_PAUSE);
      this.currentState = {
        state: AVSessionManager.PlaybackState.PLAYBACK_STATE_PAUSE
      };
      await this.session?.setAVPlaybackState(this.currentState);
    });

    // 快进15
    this.session?.on('fastForward', () => {
      console.debug(TAG, `Fast forward 15s`);

      this.emitEvent(AUDIO_BACK_SESSION_EVENT_KEY, AUDIO_BACK_SESSION_EVENT.AUDIO_BACK_SESSION_EVENT_FASTFORWARD);
    });

    // 快退15s
    this.session?.on('rewind', () => {
      console.debug(TAG, `Rewind 15s`);

      this.emitEvent(AUDIO_BACK_SESSION_EVENT_KEY, AUDIO_BACK_SESSION_EVENT.AUDIO_BACK_SESSION_EVENT_REWIND);
    });

    // seek
    this.session?.on('seek', (position) => {
      console.debug(TAG, `on seek, do seek task`);

      this.emitEvent(AUDIO_BACK_SESSION_EVENT_KEY, AUDIO_BACK_SESSION_EVENT.AUDIO_BACK_SESSION_EVENT_SEEK, position);
      this.currentState.position = {
        elapsedTime: position,
        updateTime: new Date().getTime()
      };
      this.session?.setAVPlaybackState(this.currentState);
    });


  }

  /**
   * 启动长时任务
   * @param uiContext 上下文
   * @param title 媒体标题
   * @param duration 媒体时长
   */
  async startContinuousTask(uiContext: Context, title: string, duration: number) {
    this.createAVSession(title, duration);
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: uiContext.applicationInfo.name,
          abilityName: "EntryAbility",
          parameters: {
            router: "",
            tabId: "",
          },
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };

    // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
    const wantAgentObj = await wantAgent.getWantAgent(wantAgentInfo);
    console.debug(TAG, `startContinuousTask`);

    this.session?.setLaunchAbility(wantAgentObj);

    backgroundTaskManager.startBackgroundRunning(uiContext,
      ['audioPlayback'], wantAgentObj).then((res: backgroundTaskManager.ContinuousTaskNotification) => {
      console.debug(TAG, `startContinuousTask success`);
      console.debug(TAG, `Succeeded in operationing startBackgroundRunning notification id:` + res.notificationId);
      setTimeout(() => {
        this.audioModeStartContinuousTaskCompleteSucceeded = true;
        this.emitEvent(AUDIO_CONTINUOUS_COMPELETE_EVENT_KEY, AUDIO_CONTINUOUS_COMPELETE_EVENT.CONTINUOUS_COMPELETE_SUCCESS);
      }, 500);
    }).catch((err: BusinessError) => {
      console.debug(TAG, `startContinuousTask error`);
      console.debug(TAG, `Failed to operation startBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
      setTimeout(() => {
        this.audioModeStartContinuousTaskCompleteError = true;
        this.unregisterSessionListener();
        getContext(this)
          .eventHub
          .emit(AUDIO_CONTINUOUS_COMPELETE_EVENT_KEY, AUDIO_CONTINUOUS_COMPELETE_EVENT.CONTINUOUS_COMPELETE_ERROR);
      }, 500);
    });
  }

  /**
   * 注销Session监听器
   */
  unregisterSessionListener() {
    this.session?.off('play');
    this.session?.off('pause');
    this.session?.off('fastForward');
    this.session?.off('rewind');
    this.session?.off('seek');
    this.session?.deactivate();
    this.session?.destroy();
  }

  /**
   * 停止长时任务
   * @param uiContext 上下文
   */
  async stopContinuousTask(uiContext: Context) {
    this.unregisterSessionListener();
    this.audioModeStartContinuousTaskCompleteSucceeded = false;
    this.audioModeStartContinuousTaskCompleteSucceeded = false;
    backgroundTaskManager.stopBackgroundRunning(uiContext, (err, _) => {
      if (err) {
        console.debug(TAG, `Failed to operation stopContinuousTask. Code is ${err.code}, message is ${err.message}`);
      } else {
        console.debug(TAG, `stopContinuousTask success`);
      }
    });
  }

  /**
   * 触发事件
   * @param eventKey 事件键
   * @param event 事件枚举值
   * @param data 可选的事件数据
   */
  private emitEvent(eventKey: string, event: AUDIO_BACK_SESSION_EVENT | AUDIO_CONTINUOUS_COMPELETE_EVENT, data?: number): void {
    getContext(this).eventHub.emit(eventKey, event, data);
  }

}

export default AudioContinuousTaskManager.getInstance();
