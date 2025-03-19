
import SnapKit
import UIKit

final class UnlockView: UIControl {
    private let proImageView = UIImageView()
    private let firstLabel = UILabel()
    private let secondLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawSelf()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func drawSelf() {
        backgroundColor = .clear
        proImageView.image = R.image.sub_pro_image()

        firstLabel.do { make in
            make.text = L.subFirstLabel().uppercased()
            make.textColor = UIColor.textMain
            make.numberOfLines = 0
            make.textAlignment = .center
            if UIDevice.isIphoneBelowX {
                make.font = UIFont.CustomFont.title1Bold
            } else {
                make.font = UIFont.CustomFont.largeTitleBold
            }
        }

        secondLabel.do { make in
            make.text = L.subSecondLabel()
            make.font = UIFont.CustomFont.subheadlineRegular
            make.textColor = UIColor.textSecondary
            make.numberOfLines = 0
            make.textAlignment = .center
        }

        addSubviews(proImageView, firstLabel, secondLabel)
    }

    private func setupConstraints() {
        proImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        firstLabel.snp.makeConstraints { make in
            make.top.equalTo(proImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }

        secondLabel.snp.makeConstraints { make in
            make.top.equalTo(firstLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(20)
        }
    }
}
