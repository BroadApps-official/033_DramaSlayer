import AVFoundation
import UIKit

protocol DiscoverCellDelegate: AnyObject {
    func shareVideo(url: String, from button: UIButton)
}

final class DiscoverCell: UICollectionViewCell {
    static let identifier = "DiscoverCell"
    weak var delegate: DiscoverCellDelegate?

    private var episode: Episode?
    private var video: Video?

    private let videoView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    static var cachedPlayers = [String: AVPlayer]()

    private let playButton = UIButton()
    let blurEffect = UIBlurEffect(style: .light)
    private let blurEffectView: UIVisualEffectView

    var isVideoPlaying = false
    private var isSoundOn = true

    private let favButton = UIButton()
    private let shareButton = UIButton()

    var isPlaying: Bool {
        return player?.timeControlStatus == .playing
    }

    override init(frame: CGRect) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        super.init(frame: frame)
        contentView.backgroundColor = .white.withAlphaComponent(0.05)
        setupUI()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        videoView.addGestureRecognizer(tapGesture)
        videoView.isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        blurEffectView.do { make in
            make.layer.cornerRadius = 38
            make.layer.masksToBounds = true
            make.isHidden = true
            make.isUserInteractionEnabled = false
        }

        playButton.do { make in
            make.layer.cornerRadius = 32
            make.setImage(R.image.home_pause_icon(), for: .normal)
            make.tintColor = .white
            make.addTarget(self, action: #selector(didTapPlayButton), for: .touchUpInside)
            make.isHidden = true
        }

        favButton.do { make in
            let image = (video?.isFavourite ?? false) ? R.image.home_fav_on() : R.image.home_fav_off()
            make.setImage(image, for: .normal)
            make.addTarget(self, action: #selector(favButtonTapped), for: .touchUpInside)
        }

        shareButton.do { make in
            var config = UIButton.Configuration.plain()
            config.image = R.image.home_share()
            config.title = L.share()
            config.imagePlacement = .top
            config.imagePadding = 4
            config.baseForegroundColor = UIColor.textMain
            config.attributedTitle = AttributedString(L.share(), attributes: AttributeContainer([.font: UIFont.CustomFont.footnoteSemibold]))

            make.configuration = config

            make.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
            make.addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
            make.addTarget(self, action: #selector(buttonTouchUp), for: [.touchUpInside, .touchUpOutside])
        }

        contentView.addSubview(videoView)
        contentView.addSubview(blurEffectView)
        contentView.addSubview(playButton)
        contentView.addSubview(favButton)
        contentView.addSubview(shareButton)

        videoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        playButton.snp.makeConstraints { make in
            make.center.equalTo(blurEffectView.snp.center)
            make.size.equalTo(64)
        }

        blurEffectView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(76)
        }

        favButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-182)
        }

        shareButton.snp.makeConstraints { make in
            make.centerX.equalTo(favButton.snp.centerX)
            make.bottom.equalTo(favButton.snp.top).offset(-40)
        }
    }

    @objc private func didTapPlayButton() {
        guard let player = player else { return }

        stopAllVideos()
        player.play()
        isVideoPlaying = true
        blurEffectView.isHidden = true
        playButton.isHidden = true
        isSoundOn = true
        player.volume = 1.0
    }

    @objc private func favButtonTapped() {
        guard var video = video else {
            return
        }
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
        guard let episode = episode else { return }

        let secretKey = "vMRUBUn0EWSTZnM4sGoCHIe4NLqRfgYYHGgznbGt"
        let decodedUrl = NetworkService.shared.decryptData(data: episode.videoUrl ?? "", secretKey: secretKey)

        delegate?.shareVideo(url: decodedUrl, from: shareButton)
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

    func configure(with episode: Episode, video: Video?) {
        self.episode = episode

        if let video = video {
            self.video = video
            let newImage = video.isFavourite ? R.image.home_fav_on() : R.image.home_fav_off()
            favButton.setImage(newImage, for: .normal)
        } else {
            self.video = nil
            favButton.setImage(R.image.home_fav_off(), for: .normal)
        }

        if !isVideoPlaying {
            loadVideo(for: episode)
        }
    }

    func updateFavouriteStatus(isFavourite: Bool) {
        let newImage = isFavourite ? R.image.home_fav_on() : R.image.home_fav_off()
        favButton.setImage(newImage, for: .normal)
    }
    
    private func loadVideo(for episode: Episode) {
        let secretKey = "vMRUBUn0EWSTZnM4sGoCHIe4NLqRfgYYHGgznbGt"
        let decodedUrlString = NetworkService.shared.decryptData(data: episode.videoUrl ?? "", secretKey: secretKey)
        guard let decodedUrl = URL(string: decodedUrlString) else {
            print("Invalid URL – \(decodedUrlString)")
            return
        }
        
        stopAllVideos()
        
        if UIDevice.isIpad {
            player = AVPlayer(url: decodedUrl)
            player?.volume = isSoundOn ? 1.0 : 0.0
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async { [weak self] in
                self?.playerLayer?.frame = self?.videoView.bounds ?? CGRect.zero
                if self?.playerLayer?.superlayer == nil {
                    self?.videoView.layer.addSublayer(self?.playerLayer ?? CALayer())
                }
            }
            
            player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["playable"]) {
                DispatchQueue.main.async { [weak self] in
                    var error: NSError?
                    let status = self?.player?.currentItem?.asset.statusOfValue(forKey: "playable", error: &error)
                    
                    if status == .loaded {
                        self?.attemptPlayVideo()
                    } else {
                        print("Asset is not playable: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            if let cachedPlayer = DiscoverCell.cachedPlayers[decodedUrlString] {
                player = cachedPlayer
                playerLayer = AVPlayerLayer(player: player)
                DispatchQueue.main.async { [weak self] in
                    self?.playerLayer?.frame = self?.videoView.bounds ?? CGRect.zero
                    if self?.playerLayer?.superlayer == nil {
                        self?.videoView.layer.addSublayer(self?.playerLayer ?? CALayer())
                    }
                }
            } else {
                player = AVPlayer(url: decodedUrl)
                player?.volume = isSoundOn ? 1.0 : 0.0
                playerLayer = AVPlayerLayer(player: player)
                playerLayer?.videoGravity = .resizeAspectFill
                
                DispatchQueue.main.async { [weak self] in
                    self?.playerLayer?.frame = self?.videoView.bounds ?? CGRect.zero
                    if self?.playerLayer?.superlayer == nil {
                        self?.videoView.layer.addSublayer(self?.playerLayer ?? CALayer())
                    }
                }
                
                DiscoverCell.cachedPlayers[decodedUrlString] = player
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restartVideo),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
        
        player?.currentItem?.asset.loadValuesAsynchronously(forKeys: ["playable"]) {
            DispatchQueue.main.async { [weak self] in
                var error: NSError?
                let status = self?.player?.currentItem?.asset.statusOfValue(forKey: "playable", error: &error)
                
                if status == .loaded {
                    self?.attemptPlayVideo()
                } else {
                    print("Asset is not playable: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }

    private func attemptPlayVideo() {
        if player?.timeControlStatus == .paused {
            player?.playImmediately(atRate: 1.0)
        } else {
            print("Player is already playing.")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if self?.player?.timeControlStatus == .playing {
                self?.isVideoPlaying = true
            } else {
                print("Player did not start playing. Current time control status: \(self?.player?.timeControlStatus.rawValue ?? -1)")
            }
        }
    }

    @objc private func restartVideo() {
        player?.seek(to: .zero)
        player?.play()
    }

    func startPlayingVideo() {
        guard let player = player else { return }
        player.seek(to: .zero) { [weak self] _ in
            player.play()
            self?.isVideoPlaying = true
            self?.blurEffectView.isHidden = true
            self?.playButton.isHidden = true
            self?.isSoundOn = true
            player.volume = 1.0
        }
    }

    func resetVideo() {
        player?.pause()
        player?.seek(to: .zero)
        isVideoPlaying = false
        blurEffectView.isHidden = true
        playButton.isHidden = true
        isSoundOn = false
        player?.volume = 0.0
    }

    private func stopAllVideos() {
        for (_, player) in DiscoverCell.cachedPlayers {
            player.pause()
            player.volume = 0.0
        }
    }

    @objc private func handleTap() {
        guard let player = player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
            isVideoPlaying = false
            blurEffectView.isHidden = false
            playButton.isHidden = false
            isSoundOn = false
            player.volume = 0.0
        } else {
            stopAllVideos()
            player.play()
            isVideoPlaying = true
            blurEffectView.isHidden = true
            playButton.isHidden = true
            isSoundOn = true
            player.volume = 1.0
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        DispatchQueue.main.async { [weak self] in
            self?.playerLayer?.frame = self?.videoView.bounds ?? CGRect.zero
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        if let episode = episode, let player = player {
            let secretKey = "vMRUBUn0EWSTZnM4sGoCHIe4NLqRfgYYHGgznbGt"
            let decodedUrlString = NetworkService.shared.decryptData(data: episode.videoUrl ?? "", secretKey: secretKey)
            DiscoverCell.cachedPlayers.removeValue(forKey: decodedUrlString)
        }

        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = nil
        playerLayer = nil
        isVideoPlaying = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
}
