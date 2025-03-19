import SnapKit
import UIKit

final class LaunchScreenViewController: UIViewController {
    private let mainImageView = UIImageView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.bgMain
        mainImageView.image = R.image.launch_image()
        activityIndicator.color = UIColor.colorsSecondary
        activityIndicator.startAnimating()

        view.addSubviews(mainImageView, activityIndicator)

        mainImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-40)
        }
    }
}
