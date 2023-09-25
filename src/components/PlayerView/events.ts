import { NativeSyntheticEvent } from 'react-native';
import {
  AdBreakFinishedEvent,
  AdBreakStartedEvent,
  AdClickedEvent,
  AdErrorEvent,
  AdFinishedEvent,
  AdManifestLoadedEvent,
  AdManifestLoadEvent,
  AdQuartileEvent,
  AdScheduledEvent,
  AdSkippedEvent,
  AdStartedEvent,
  CastAvailableEvent,
  CastPausedEvent,
  CastPlaybackFinishedEvent,
  CastPlayingEvent,
  CastStartedEvent,
  CastStartEvent,
  CastStoppedEvent,
  CastTimeUpdatedEvent,
  CastWaitingForDeviceEvent,
  DestroyEvent,
  Event,
  FullscreenEnabledEvent,
  FullscreenDisabledEvent,
  FullscreenEnterEvent,
  FullscreenExitEvent,
  MutedEvent,
  PausedEvent,
  PictureInPictureAvailabilityChangedEvent,
  PictureInPictureEnterEvent,
  PictureInPictureEnteredEvent,
  PictureInPictureExitEvent,
  PictureInPictureExitedEvent,
  PlaybackFinishedEvent,
  PlayerActiveEvent,
  PlayerErrorEvent,
  PlayerWarningEvent,
  PlayEvent,
  PlayingEvent,
  ReadyEvent,
  SeekedEvent,
  SeekEvent,
  TimeShiftEvent,
  TimeShiftedEvent,
  StallStartedEvent,
  StallEndedEvent,
  SourceErrorEvent,
  SourceLoadedEvent,
  SourceLoadEvent,
  SourceUnloadedEvent,
  SourceWarningEvent,
  AudioAddedEvent,
  AudioChangedEvent,
  AudioRemovedEvent,
  SubtitleAddedEvent,
  SubtitleChangedEvent,
  SubtitleRemovedEvent,
  TimeChangedEvent,
  UnmutedEvent,
  VideoPlaybackQualityChangedEvent,
} from '../../events';

/**
 * Type that defines all event props supported by `PlayerView` and `NativePlayerView`.
 * Used to generate the specific events interface for each component.
 */
interface EventProps {
  onAdBreakFinished: AdBreakFinishedEvent;
  onAdBreakStarted: AdBreakStartedEvent;
  onAdClicked: AdClickedEvent;
  onAdError: AdErrorEvent;
  onAdFinished: AdFinishedEvent;
  onAdManifestLoad: AdManifestLoadEvent;
  onAdManifestLoaded: AdManifestLoadedEvent;
  onAdQuartile: AdQuartileEvent;
  onAdScheduled: AdScheduledEvent;
  onAdSkipped: AdSkippedEvent;
  onAdStarted: AdStartedEvent;
  onCastAvailable: CastAvailableEvent;
  onCastPaused: CastPausedEvent;
  onCastPlaybackFinished: CastPlaybackFinishedEvent;
  onCastPlaying: CastPlayingEvent;
  onCastStarted: CastStartedEvent;
  onCastStart: CastStartEvent;
  onCastStopped: CastStoppedEvent;
  onCastTimeUpdated: CastTimeUpdatedEvent;
  onCastWaitingForDevice: CastWaitingForDeviceEvent;
  onDestroy: DestroyEvent;
  onEvent: Event;
  onFullscreenEnabled: FullscreenEnabledEvent;
  onFullscreenDisabled: FullscreenDisabledEvent;
  onFullscreenEnter: FullscreenEnterEvent;
  onFullscreenExit: FullscreenExitEvent;
  onMuted: MutedEvent;
  onPaused: PausedEvent;
  onPictureInPictureAvailabilityChanged: PictureInPictureAvailabilityChangedEvent;
  onPictureInPictureEnter: PictureInPictureEnterEvent;
  onPictureInPictureEntered: PictureInPictureEnteredEvent;
  onPictureInPictureExit: PictureInPictureExitEvent;
  onPictureInPictureExited: PictureInPictureExitedEvent;
  onPlay: PlayEvent;
  onPlaybackFinished: PlaybackFinishedEvent;
  onPlayerActive: PlayerActiveEvent;
  onPlayerError: PlayerErrorEvent;
  onPlayerWarning: PlayerWarningEvent;
  onPlaying: PlayingEvent;
  onReady: ReadyEvent;
  onSeek: SeekEvent;
  onSeeked: SeekedEvent;
  onTimeShift: TimeShiftEvent;
  onTimeShifted: TimeShiftedEvent;
  onStallStarted: StallStartedEvent;
  onStallEnded: StallEndedEvent;
  onSourceError: SourceErrorEvent;
  onSourceLoad: SourceLoadEvent;
  onSourceLoaded: SourceLoadedEvent;
  onSourceUnloaded: SourceUnloadedEvent;
  onSourceWarning: SourceWarningEvent;
  onAudioAdded: AudioAddedEvent;
  onAudioChanged: AudioChangedEvent;
  onAudioRemoved: AudioRemovedEvent;
  onSubtitleAdded: SubtitleAddedEvent;
  onSubtitleChanged: SubtitleChangedEvent;
  onSubtitleRemoved: SubtitleRemovedEvent;
  onTimeChanged: TimeChangedEvent;
  onUnmuted: UnmutedEvent;
  onVideoPlaybackQualityChanged: VideoPlaybackQualityChangedEvent;
}

/**
 * Event props for `PlayerView`.
 *
 * Note the events of `PlayerView` are simply a proxy over
 * the events from `NativePlayerView` just removing RN's bubbling data.
 */
export type PlayerViewEvents = {
  [Prop in keyof EventProps]?: (event: EventProps[Prop]) => void;
};

/**
 * Event props for `NativePlayerView`.
 */
export type NativePlayerViewEvents = {
  [Prop in keyof EventProps]?: (
    nativeEvent: NativeSyntheticEvent<EventProps[Prop]>
  ) => void;
};
