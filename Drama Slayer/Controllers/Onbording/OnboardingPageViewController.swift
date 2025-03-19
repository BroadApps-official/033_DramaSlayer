import AVKit
import UIKit

final class OnboardingPageViewController: UIViewController {
    // MARK: - Types

    enum Page {
        case unique, sharp, passion, rate, notifications
    }

    private let mainLabel = UILabel()
    private let subLabel = UILabel()
    private let imageView = UIImageView()
    private let secondImageView = UIImageView()
    private let shadowImageView = UIImageView()

    private let exitButton = UIButton(type: .system)

    private let videoView = UIView()
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    // MARK: - Properties info

    private let page: Page

    // MARK: - Init

    init(page: Page) {
        self.page = page
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.bgMain

        switch page {
        case .unique: drawUnique()
        case .sharp: drawSharp()
        case .passion: drawPassion()
        case .rate: drawRate()
        case .notifications: drawNotifications()
        }
    }

    // MARK: - Draw

    private func drawUnique() {
        imageView.image = R.image.onb_unique_image()

        mainLabel.do { make in
            make.text = L.uniqueLabel()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.title1Bold
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        subLabel.do { make in
            make.text = L.uniqueSubLabel()
            make.textColor = UIColor.textSecondary
            make.font = UIFont.CustomFont.subheadlineRegular
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, subLabel, mainLabel)

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            if UIDevice.isIpad {
                make.height.equalTo(UIScreen.main.bounds.height * (644.0 / 844.0))
            }
        }

        mainLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(subLabel.snp.top).offset(-12)
            } else {
                make.top.equalTo(imageView.snp.bottom)
            }
        }

        subLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-150)
            } else {
                make.top.equalTo(mainLabel.snp.bottom).offset(12)
            }
        }
    }

    private func drawSharp() {
        imageView.image = R.image.onb_sharp_image()

        mainLabel.do { make in
            make.text = L.sharpLabel()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.title1Bold
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        subLabel.do { make in
            make.text = L.sharpSubLabel()
            make.textColor = UIColor.textSecondary
            make.font = UIFont.CustomFont.subheadlineRegular
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, subLabel, mainLabel)

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            if UIDevice.isIpad {
                make.height.equalTo(UIScreen.main.bounds.height * (644.0 / 844.0))
            }
        }

        mainLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(subLabel.snp.top).offset(-12)
            } else {
                make.top.equalTo(imageView.snp.bottom)
            }
        }

        subLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-150)
            } else {
                make.top.equalTo(mainLabel.snp.bottom).offset(12)
            }
        }
    }

    private func drawPassion() {
        imageView.image = R.image.onb_passion_image()

        mainLabel.do { make in
            make.text = L.passionLabel()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.title1Bold
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        subLabel.do { make in
            make.text = L.passionSubLabel()
            make.textColor = UIColor.textSecondary
            make.font = UIFont.CustomFont.subheadlineRegular
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, subLabel, mainLabel)

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            if UIDevice.isIpad {
                make.height.equalTo(UIScreen.main.bounds.height * (644.0 / 844.0))
            }
        }

        mainLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(subLabel.snp.top).offset(-12)
            } else {
                make.top.equalTo(imageView.snp.bottom)
            }
        }

        subLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-150)
            } else {
                make.top.equalTo(mainLabel.snp.bottom).offset(12)
            }
        }
    }

    private func drawRate() {
        imageView.image = R.image.onb_rate_image()

        mainLabel.do { make in
            make.text = L.rateLabel()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.title1Bold
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        subLabel.do { make in
            make.text = L.rateSubLabel()
            make.textColor = UIColor.textSecondary
            make.font = UIFont.CustomFont.subheadlineRegular
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, subLabel, mainLabel)

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            if UIDevice.isIpad {
                make.height.equalTo(UIScreen.main.bounds.height * (644.0 / 844.0))
            }
        }

        mainLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(subLabel.snp.top).offset(-12)
            } else {
                make.top.equalTo(imageView.snp.bottom)
            }
        }

        subLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-150)
            } else {
                make.top.equalTo(mainLabel.snp.bottom).offset(12)
            }
        }
    }

    private func drawNotifications() {
        imageView.image = R.image.onb_notifications_image()

        mainLabel.do { make in
            make.text = L.notificationsLabel()
            make.textColor = UIColor.textMain
            make.font = UIFont.CustomFont.title1Bold
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        subLabel.do { make in
            make.text = L.notificationsSubLabel()
            make.textColor = UIColor.textSecondary
            make.font = UIFont.CustomFont.subheadlineRegular
            make.textAlignment = .center
            make.numberOfLines = 0
        }

        view.addSubviews(imageView, subLabel, mainLabel)

        imageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            if UIDevice.isIpad {
                make.height.equalTo(UIScreen.main.bounds.height * (644.0 / 844.0))
            }
        }

        mainLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(subLabel.snp.top).offset(-12)
            } else {
                make.top.equalTo(imageView.snp.bottom)
            }
        }

        subLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(37)
            if UIDevice.isIphoneBelowX {
                make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-150)
            } else {
                make.top.equalTo(mainLabel.snp.bottom).offset(12)
            }
        }
    }
}
