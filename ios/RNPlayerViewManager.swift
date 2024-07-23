import BitmovinPlayer
import Foundation

@objc(RNPlayerViewManager)
public class RNPlayerViewManager: RCTViewManager {
    /// Initialize module on main thread.
    override public static func requiresMainQueueSetup() -> Bool {
        true
    }

    /// `UIView` factory function. It gets called for each `<NativePlayerView />` component
    /// from React.
    override public func view() -> UIView! { // swiftlint:disable:this implicitly_unwrapped_optional
        RNPlayerView()
    }

    private var customMessageHandlerBridgeId: NativeId?

    /**
     Sets the `Player` instance for the view with `viewId` inside RN's `UIManager` registry.
     - Parameter viewId: `RNPlayerView` id inside `UIManager`'s registry.
     - Parameter playerId: `Player` instance id inside `PlayerModule`'s registry.
     */
    @objc
    func attachPlayer(_ viewId: NSNumber, playerId: NativeId, playerConfig: NSDictionary?) {
        bridge.uiManager.addUIBlock { [weak self] _, views in
            guard
                let self,
                let view = views?[viewId] as? RNPlayerView,
                let player = self.getPlayerModule()?.retrieve(playerId)
            else {
                return
            }
            let playerViewConfig = RCTConvert.rnPlayerViewConfig(view.config)

            if let userInterfaceConfig = maybeCreateUserInterfaceConfig(
                styleConfig: player.config.styleConfig,
                playerViewConfig: playerViewConfig
            ) {
              player.config.styleConfig.userInterfaceConfig = userInterfaceConfig
            }

            let previousPictureInPictureAvailableValue: Bool
            if let playerView = view.playerView {
                playerView.player = player
                previousPictureInPictureAvailableValue = playerView.isPictureInPictureAvailable
            } else {
                let playerView: PlayerView
                
                if player.config.styleConfig.userInterfaceType == .system {
                    playerView = iOSNativePlayView(
                        player: player,
                        frame: view.bounds,
                        playerViewConfig: playerViewConfig?.playerViewConfig ?? PlayerViewConfig()
                    )
                } else {
                    playerView = PlayerView(
                        player: player,
                        frame: view.bounds,
                        playerViewConfig: playerViewConfig?.playerViewConfig ?? PlayerViewConfig()
                    )
                }
                view.playerView = playerView
                previousPictureInPictureAvailableValue = false
            }
            player.add(listener: view)
            view.playerView?.add(listener: view)

            self.maybeEmitPictureInPictureAvailabilityEvent(
                for: view,
                previousState: previousPictureInPictureAvailableValue
            )
        }
    }

    private func maybeCreateUserInterfaceConfig(
        styleConfig: StyleConfig,
        playerViewConfig: RNPlayerViewConfig?
    ) -> UserInterfaceConfig? {
#if os(iOS)
        if styleConfig.userInterfaceType == .bitmovin {
            let bitmovinUserInterfaceConfig = styleConfig
                .userInterfaceConfig as? BitmovinUserInterfaceConfig ?? BitmovinUserInterfaceConfig()

            if let uiConfig = playerViewConfig?.uiConfig {
                bitmovinUserInterfaceConfig
                    .playbackSpeedSelectionEnabled = uiConfig.playbackSpeedSelectionEnabled
            }
            if let hideFirstFrame = playerViewConfig?.hideFirstFrame {
                bitmovinUserInterfaceConfig.hideFirstFrame = hideFirstFrame
            }

            if let customMessageHandlerBridgeId = self.customMessageHandlerBridgeId,
               let customMessageHandlerBridge = self.bridge[CustomMessageHandlerModule.self]?
                .retrieve(customMessageHandlerBridgeId) {
                bitmovinUserInterfaceConfig.customMessageHandler = customMessageHandlerBridge.customMessageHandler
            }

            return bitmovinUserInterfaceConfig
        }
#endif
        if styleConfig.userInterfaceType == .system {
            let systemUserInterfaceConfig = styleConfig
                .userInterfaceConfig as? SystemUserInterfaceConfig ?? SystemUserInterfaceConfig()

            if let hideFirstFrame = playerViewConfig?.hideFirstFrame {
                systemUserInterfaceConfig.hideFirstFrame = hideFirstFrame
            }

            return systemUserInterfaceConfig
        }

        return nil
    }

    @objc
    func attachFullscreenBridge(_ viewId: NSNumber, fullscreenBridgeId: NativeId) {
        bridge.uiManager.addUIBlock { [weak self] _, views in
            guard
                let view = views?[viewId] as? RNPlayerView,
                let fullscreenBridge = self?.getFullscreenHandlerModule()?.retrieve(fullscreenBridgeId)
            else {
                return
            }
            guard let playerView = view.playerView else {
                return
            }

            playerView.fullscreenHandler = fullscreenBridge
        }
    }

    @objc
    func setCustomMessageHandlerBridgeId(_ viewId: NSNumber, customMessageHandlerBridgeId: NativeId) {
        self.customMessageHandlerBridgeId = customMessageHandlerBridgeId
    }

    @objc
    func setFullscreen(_ viewId: NSNumber, isFullscreen: Bool) {
        bridge.uiManager.addUIBlock { [weak self] _, views in
            guard
                let self,
                let view = views?[viewId] as? RNPlayerView,
                let playerView = view.playerView else {
                return
            }
            guard playerView.isFullscreen != isFullscreen else {
                return
            }
            if isFullscreen {
                playerView.enterFullscreen()
            } else {
                playerView.exitFullscreen()
            }
        }
    }

    @objc
    func setPictureInPicture(_ viewId: NSNumber, enterPictureInPicture: Bool) {
        bridge.uiManager.addUIBlock { [weak self] _, views in
            guard
                let self,
                let view = views?[viewId] as? RNPlayerView,
                let playerView = view.playerView else {
                return
            }
            guard playerView.isPictureInPicture != enterPictureInPicture else {
                return
            }
            if enterPictureInPicture {
                playerView.enterPictureInPicture()
            } else {
                playerView.exitPictureInPicture()
            }
        }
    }

    @objc
    func setScalingMode(_ viewId: NSNumber, scalingMode: String) {
        bridge.uiManager.addUIBlock { [weak self] _, views in
            guard
                let self,
                let view = views?[viewId] as? RNPlayerView
            else {
                return
            }
            guard let playerView = view.playerView else {
                return
            }
            switch scalingMode {
            case "Zoom":
                playerView.scalingMode = .zoom
            case "Stretch":
                playerView.scalingMode = .stretch
            case "Fit":
                playerView.scalingMode = .fit
            default:
                break
            }
        }
    }

    /// Fetches the initialized `PlayerModule` instance on RN's bridge object.
    private func getPlayerModule() -> PlayerModule? {
        bridge.module(for: PlayerModule.self) as? PlayerModule
    }

    /// Fetches the initialized `FullscreenHandlerModule` instance on RN's bridge object.
    private func getFullscreenHandlerModule() -> FullscreenHandlerModule? {
        bridge.module(for: FullscreenHandlerModule.self) as? FullscreenHandlerModule
    }

    private func maybeEmitPictureInPictureAvailabilityEvent(for view: RNPlayerView, previousState: Bool) {
        guard let playerView = view.playerView,
              playerView.isPictureInPictureAvailable != previousState else {
            return
        }
        let event: [AnyHashable: Any] = [
            "isPictureInPictureAvailable": playerView.isPictureInPictureAvailable,
            "name": "onPictureInPictureAvailabilityChanged",
            "timestamp": Date().timeIntervalSince1970
        ]
        view.onBmpPictureInPictureAvailabilityChanged?(event)
    }
}


import Combine
class iOSNativePlayView: PlayerView {
    @objc var fullscreenButton: UIButton?
    @objc var avPlayerView: UIView?
    var fullScreen: Bool = false

    public override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let avPlayerView = avPlayerView, fullscreenButton == nil else { return }
        setFullScreenButton(in: avPlayerView)
    }
    
    public override func didAddSubview(_ subview: UIView) {
        if (NSStringFromClass(type(of: subview)) == "AVPlayerView") {
            avPlayerView = subview
        }
        
        super.didAddSubview(subview)
    }
    
    private func setFullScreenButton(in view: UIView) {
        for subview in view.subviews {
            if NSStringFromClass(type(of: subview)) == "AVButton" {
                if let avButton = subview as? UIButton, isFullScreenButton(avButton)  {
                    fullscreenButton = avButton
                    avButton.addTarget(self, action: #selector(fullScreenButtonWasPressed), for: .touchUpInside)
                    return
                }
            }
            
            setFullScreenButton(in: subview)
        }
    }
    
    private func isFullScreenButton(_ button: UIButton) -> Bool {
        for target in button.allTargets {
            if let actions = button.actions(forTarget: target, forControlEvent: .touchUpInside) {
                if actions.contains("fullScreenButtonWasPressed") {
                    return true
                }
            }
        }
        return false
    }
    
    @objc func fullScreenButtonWasPressed() {
        fullScreen.toggle()
        fullScreen ? enterFullscreen():exitFullscreen()
    }
    
    public override init(player: Player, frame: CGRect, playerViewConfig: PlayerViewConfig) {
        super.init(player: player, frame: frame, playerViewConfig: playerViewConfig)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
  
    
    @objc func orientationChanged(_ notification: Notification) {
        guard fullScreen == false, fullscreenButton != nil else { return }
        let deviceOrientation = UIDevice.current.orientation

        if deviceOrientation.isLandscape {
            fullscreenButton?.sendActions(for: .touchUpInside)
        }
    }

    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if self.window != nil {
            if fullScreen {
                fullScreen = false
                exitFullscreen()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

