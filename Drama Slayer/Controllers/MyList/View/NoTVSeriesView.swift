import SnapKit
import UIKit

protocol NoTvSeriesViewDelegate: AnyObject {
    func addButtonTapped()
}

final class NoTvSeriesView: UIControl {
    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let addButton = MainButton()
    weak var delegate: NoTvSeriesViewDelegate?

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

        firstLabel.do { make in
            make.text = L.noSeriesLabel()
            make.font = UIFont.CustomFont.title2Bold
            make.textAlignment = .center
            make.textColor = UIColor.textMain
            make.numberOfLines = 0
        }

        secondLabel.do { make in
            make.text = L.noSeriesSubLabel()
            make.font = UIFont.CustomFont.bodyRegular
            make.textAlignment = .center
            make.textColor = .white.withAlphaComponent(0.7)
            make.numberOfLines = 0
        }

        addButton.do { make in
            make.addMode()
            let tapSelectGesture = UITapGestureRecognizer(target: self, action: #selector(addButtonTapped))
            make.addGestureRecognizer(tapSelectGesture)
        }

        addSubviews(firstLabel, secondLabel, addButton)
    }

    private func setupConstraints() {
        firstLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(28)
        }

        secondLabel.snp.makeConstraints { make in
            make.top.equalTo(firstLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        addButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(54)
            make.width.equalTo(195)
        }
    }

    @objc private func addButtonTapped() {
        delegate?.addButtonTapped()
    }
}
