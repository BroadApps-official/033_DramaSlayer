import AVKit
import UIKit

protocol PlayerDelegate: AnyObject {
    func updateVideoModel(videoId: Int)
}

final class PlayerViewController: UIViewController {
    private var video: Video
    private var currentEpisode: Episode?
    private var episodes: [Episode]?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isNavBarHidden = false

    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView
    private var isPlaying = true

    private var timeObserver: Any?
    private let durationLabel = UILabel()
    private let currentTimeLabel = UILabel()
    let audioSlider = UISlider()
    var wasPlayingBeforeSeeking = false
    private var currentVideoSize: CGSize?

    private let favButton = UIButton()
    private let shareButton = UIButton()
    private var decodedUrl = String()
    private var episodeView = EpisodeView()

    weak var delegate: PlayerDelegate?

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }

    init(video: Video) {
        self.video = video
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.bgMain
        setupNavBar()
        setupTapGesture()
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")

        Task {
            do {
                let episodes = try await NetworkService.shared.fetchVideoEpisodes(videoId: video.id)
                currentEpisode = episodes.first
                self.episodes = episodes
                guard let firstEpisode = episodes.first else {
                    print("No available episodes")
                    return
                }

                let secretKey = "vMRUBUn0EWSTZnM4sGoCHIe4NLqRfgYYHGgznbGt"
                let decodedUrl = NetworkService.shared.decryptData(data: firstEpisode.videoUrl ?? "", secretKey: secretKey)
                self.decodedUrl = decodedUrl

                DispatchQueue.main.async {
                    self.episodeView.configure(currentEpisode: firstEpisode.episode, totalEpisode: self.video.totalEpisodes)
                    self.episodeView.isHidden = false
                }

                playVideo(urlString: decodedUrl)
            } catch {
                print("Load episode error: \(error)")
            }
        }

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.orientationLock = .all
        }

        drawSelf()
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        player?.pause()
        player = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        player = nil
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        let orientationRawValue = UIDevice.current.orientation.rawValue
        coordinator.animate(alongsideTransition: { _ in
            self.updateNavBarVisibility(orientationRawValue: orientationRawValue)

            if let videoSize = self.currentVideoSize {
                self.updatePlayerLayerFrame(size: size, videoSize: videoSize)
            }
        })
    }

    private func updatePlayerLayerFrame(size: CGSize, videoSize: CGSize) {
        guard let playerLayer = playerLayer else { return }

        let videoAspectRatio = videoSize.width / videoSize.height
        let screenAspectRatio = size.width / size.height

        var newFrame: CGRect

        if videoAspectRatio > 1 {
            if screenAspectRatio > 1 {
                newFrame = CGRect(x: 0, y: 0, width: size.width, height: size.width / videoAspectRatio)
            } else {
                newFrame = CGRect(x: 0, y: 0, width: size.width, height: size.width / videoAspectRatio)
            }
        } else {
            if screenAspectRatio > 1 {
                newFrame = CGRect(x: 0, y: 0, width: size.height * videoAspectRatio, height: size.height)
            } else {
                newFrame = CGRect(x: 0, y: 0, width: size.width, height: size.width / videoAspectRatio)
            }
        }

        playerLayer.frame = newFrame
        playerLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    private func setupNavBar() {
        guard let navBar = navigationController?.navigationBar else { return }
        navBar.tintColor = .white
        navBar.titleTextAttributes = [.foregroundColor: UIColor.white]

        let backButton = UIBarButtonItem(
            image: R.image.home_back_icon(),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )

        let rotateButton = UIBarButtonItem(
            image: R.image.home_rotate_icon(),
            style: .plain,
            target: self,
            action: #selector(toggleRotation)
        )

        navigationItem.leftBarButtonItem = backButton
        navigationItem.rightBarButtonItem = rotateButton
        navigationItem.title = video.title
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleNavBarAlpha))
        view.addGestureRecognizer(tapGesture)
    }

    private func updateNavBarVisibility(orientationRawValue: Int) {
        let elementsToAnimate: [UIView] = [
            navigationController?.navigationBar,
            blurEffectView,
            playButton,
            durationLabel,
            currentTimeLabel,
            audioSlider,
            favButton,
            shareButton,
            episodeView
        ].compactMap { $0 }

        let alpha: CGFloat = (orientationRawValue == 1) ? 1.0 : 0.0
        let isHidden: Bool = (orientationRawValue != 1)

        navigationController?.navigationBar.alpha = alpha
        navigationController?.navigationBar.isHidden = isHidden

        UIView.animate(withDuration: 0.3) {
            for element in elementsToAnimate {
                element.alpha = alpha
            }
        }
    }

    private func playVideo(urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }

        let player = AVPlayer(url: url)
        self.player = player

        let asset = AVAsset(url: url)
        let videoTrack = asset.tracks(withMediaType: .video).first
        let videoSize = videoTrack?.naturalSize.applying(videoTrack?.preferredTransform ?? .identity) ?? .zero
        currentVideoSize = videoSize

        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect

        self.playerLayer = playerLayer
        view.layer.insertSublayer(playerLayer, at: 0)

        player.play()
        setupTimeObserver()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updatePlayerLayerFrame(size: self.view.bounds.size, videoSize: videoSize)
        }
    }

    private func setupTimeObserver() {
        guard let player = player else { return }

        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.1, preferredTimescale: 60000), queue: .main) { [weak self] time in
            guard let self = self, let currentItem = player.currentItem else { return }

            let currentTime = CMTimeGetSeconds(time)
            let duration = CMTimeGetSeconds(currentItem.duration)

            // Отображаем время
            DispatchQueue.main.async {
                self.currentTimeLabel.text = self.formatTime(seconds: currentTime) + " /"
                self.audioSlider.value = Float(currentTime)
                self.audioSlider.maximumValue = Float(duration)
                self.durationLabel.text = self.formatTime(seconds: duration)
            }

            if currentTime >= 40 {
                self.saveVideoToUserDefaults()
            }
        }
    }

    private func formatTime(seconds: Double) -> String {
        guard !seconds.isNaN else { return "00:00 /" }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    private func saveVideoToUserDefaults() {
        var savedVideoIds = UserDefaults.standard.array(forKey: "savedVideoIds") as? [Int] ?? []

        if !savedVideoIds.contains(video.id) {
            savedVideoIds.append(video.id)
            UserDefaults.standard.set(savedVideoIds, forKey: "savedVideoIds")
        }
    }

    private func drawSelf() {
        episodeView.do { make in
            episodeView.isHidden = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(episodeSelectTapped))
            make.addGestureRecognizer(tapGesture)
        }

        blurEffectView.do { make in
            make.layer.cornerRadius = 38
            make.layer.masksToBounds = true
        }

        playButton.do { make in
            make.layer.cornerRadius = 32
            make.setImage(R.image.home_pause_icon(), for: .normal)
            make.tintColor = .white
            make.addTarget(self, action: #selector(didTapPlayButton), for: .touchUpInside)
        }

        durationLabel.do { make in
            make.textColor = UIColor.textSecondary
            make.font = UIFont.CustomFont.footnoteRegular
            make.textAlignment = .left
            make.text = "00:00"
        }

        currentTimeLabel.do { make in
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.footnoteRegular
            make.textAlignment = .left
            make.text = "00:00 /"
        }

        favButton.do { make in
            let image = video.isFavourite ? R.image.home_fav_on() : R.image.home_fav_off()
            make.setImage(image, for: .normal)
            make.addTarget(self, action: #selector(favButtonTapped), for: .touchUpInside)
        }

        shareButton.do { make in
            make.setTitle(L.share(), for: .normal)
            make.setTitleColor(UIColor.textMain, for: .normal)
            make.titleLabel?.font = UIFont.CustomFont.footnoteSemibold
            make.setImage(R.image.home_share(), for: .normal)

            make.semanticContentAttribute = .forceLeftToRight
            make.contentHorizontalAlignment = .leading
            make.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 0)

            make.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
            make.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
            make.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside])
        }

        audioSlider.addTarget(self, action: #selector(didBeginSliderDrag), for: .touchDown)
        audioSlider.addTarget(self, action: #selector(didChangeSliderValue), for: .valueChanged)
        audioSlider.addTarget(self, action: #selector(didEndSliderDrag), for: .touchUpInside)
        audioSlider.addTarget(self, action: #selector(didEndSliderDrag), for: .touchUpOutside)

        audioSlider.minimumTrackTintColor = .white
        audioSlider.maximumTrackTintColor = UIColor(hex: "#5B5B5B80").withAlphaComponent(0.5)
        let thumbImage = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let scaledThumbImage = thumbImage?.resized(to: CGSize(width: 19, height: 19))
        audioSlider.setThumbImage(scaledThumbImage, for: .normal)

        view.addSubview(blurEffectView)
        view.addSubview(playButton)
        view.addSubview(durationLabel)
        view.addSubview(currentTimeLabel)
        view.addSubview(audioSlider)
        view.addSubview(favButton)
        view.addSubview(shareButton)
        view.addSubview(episodeView)

        blurEffectView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(76)
        }

        playButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(64)
        }

        currentTimeLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(audioSlider.snp.top).offset(-16)
        }

        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(currentTimeLabel.snp.trailing).offset(4)
            make.centerY.equalTo(currentTimeLabel.snp.centerY)
        }

        audioSlider.snp.makeConstraints { make in
            make.bottom.equalTo(favButton.snp.top).offset(-24)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(3)
        }

        favButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-26.5)
        }

        shareButton.snp.makeConstraints { make in
            make.centerY.equalTo(favButton.snp.centerY)
            make.leading.equalTo(favButton.snp.trailing).offset(30)
        }

        episodeView.snp.makeConstraints { make in
            make.centerY.equalTo(favButton.snp.centerY)
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(34)
        }
    }

    @objc private func didTapPlayButton() {
        if isPlaying {
            player?.pause()
            playButton.setImage(R.image.home_play_icon(), for: .normal)
        } else {
            player?.play()
            playButton.setImage(R.image.home_pause_icon(), for: .normal)
        }
        isPlaying.toggle()
    }

    @objc private func didBeginSliderDrag() {
        wasPlayingBeforeSeeking = isPlaying
        player?.pause()
    }

    @objc private func didChangeSliderValue() {
        guard let player = player else { return }

        let newTime = CMTime(seconds: Double(audioSlider.value), preferredTimescale: 60000)
        player.seek(to: newTime, toleranceBefore: CMTime(seconds: 0.1, preferredTimescale: 60000), toleranceAfter: CMTime(seconds: 0.1, preferredTimescale: 60000))
    }

    @objc private func didEndSliderDrag() {
        if wasPlayingBeforeSeeking {
            player?.play()
        }
    }

    // MARK: - Actions

    @objc private func didTapBack() {
        guard let delegate = delegate else {
            dismiss(animated: true, completion: nil)
            return
        }

        guard let currentItem = player?.currentItem else { return }
        let currentTime = CMTimeGetSeconds(player!.currentTime())

        if currentTime >= 60 {
            saveVideoToUserDefaults()
        }

        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            delegate.updateVideoModel(videoId: self.video.id)
        }
    }

    @objc private func favButtonTapped() {
        Task {
            do {
                try await NetworkService.shared.addToFavourites(videoId: video.id)
                video.isFavourite.toggle()
                let newImage = video.isFavourite ? R.image.home_fav_on() : R.image.home_fav_off()
                favButton.setImage(newImage, for: .normal)
            } catch {
                print("Adding to favorites error: \(error)")
            }
        }
    }

    @objc private func shareButtonTapped() {
        let activityViewController = UIActivityViewController(activityItems: [decodedUrl], applicationActivities: nil)
        activityViewController.overrideUserInterfaceStyle = .dark

        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = shareButton
            popoverController.sourceRect = shareButton.bounds
        }
        present(activityViewController, animated: true)
    }

    @objc private func buttonTouchDown(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.titleLabel?.alpha = 0.5
            sender.imageView?.alpha = 0.5
        }
    }

    @objc private func buttonTouchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.05) {
            sender.titleLabel?.alpha = 1.0
            sender.imageView?.alpha = 1.0
        }
    }

    @objc private func toggleRotation() {
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }

            let currentOrientation = UIDevice.current.orientation
            let newOrientation: UIInterfaceOrientationMask = (currentOrientation == .landscapeRight) ? .portrait : .landscapeRight

            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: newOrientation)
            windowScene.requestGeometryUpdate(geometryPreferences) { (error: Error?) in
                if let error = error {
                    print("Rotation error: \(error.localizedDescription)")
                }
            }
        } else {
            let currentOrientation = UIDevice.current.orientation
            let newOrientation: UIInterfaceOrientation = (currentOrientation == .landscapeRight) ? .portrait : .landscapeRight

            UIDevice.current.setValue(newOrientation.rawValue, forKey: "orientation")
        }

        let orientationRawValue = UIDevice.current.orientation.rawValue
        updateNavBarVisibility(orientationRawValue: orientationRawValue)
    }

    @objc private func toggleNavBarAlpha() {
        guard let navBar = navigationController?.navigationBar else { return }

        let newAlpha: CGFloat = isNavBarHidden ? 1 : 0
        UIView.animate(withDuration: 0.3) {
            navBar.alpha = newAlpha
            self.blurEffectView.alpha = newAlpha
            self.playButton.alpha = newAlpha
            self.durationLabel.alpha = newAlpha
            self.currentTimeLabel.alpha = newAlpha
            self.audioSlider.alpha = newAlpha
            self.favButton.alpha = newAlpha
            self.shareButton.alpha = newAlpha
            self.episodeView.alpha = newAlpha
        }

        isNavBarHidden.toggle()
    }

    @objc func episodeSelectTapped() {
        guard let episodes = episodes else { return }
        let episodeSelectionVC = EpisodeSelectionViewController(video: video, episodes: episodes)
        episodeSelectionVC.delegate = self
        if let sheet = episodeSelectionVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(episodeSelectionVC, animated: true)
    }
}

// MARK: - EpisodeSelectionDelegate
extension PlayerViewController: EpisodeSelectionDelegate {
    func episodeSelected(episode: Episode) {
        if let currentPlayer = player {
            currentPlayer.pause()
            playerLayer?.removeFromSuperlayer()
            player = nil
        }

        currentEpisode = episode

        let secretKey = "vMRUBUn0EWSTZnM4sGoCHIe4NLqRfgYYHGgznbGt"
        let decodedUrl = NetworkService.shared.decryptData(data: episode.videoUrl ?? "", secretKey: secretKey)
        self.decodedUrl = decodedUrl

        DispatchQueue.main.async {
            self.episodeView.configure(currentEpisode: episode.episode, totalEpisode: self.video.totalEpisodes)
            self.episodeView.isHidden = false
            if !self.isPlaying {
                self.didTapPlayButton()
            }
        }

        playVideo(urlString: decodedUrl)
    }
}
