import SnapKit
import UIKit

protocol ListSelectorDelegate: AnyObject {
    func didSelect(at index: Int)
}

final class ListSelectorView: UIControl {
    private let mainContainerView = UIView()

    private let favouritesView = UIView()
    private let recentView = UIView()

    private let favouritesUnderView = UIView()
    private let recentUnderView = UIView()

    private let favouritesLabel = UILabel()
    private let recentLabel = UILabel()

    private let containerStackView = UIStackView()

    private var selectedIndex: Int = 0 {
        didSet {
            updateViewsAppearance()
        }
    }

    private var views: [UIView] = []
    weak var delegate: ListSelectorDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        mainContainerView.do { make in
            make.backgroundColor = .clear
        }

        [favouritesView, recentView].forEach { view in
            view.do { make in
                make.backgroundColor = .clear
                make.isUserInteractionEnabled = true
            }
        }

        containerStackView.do { make in
            make.axis = .horizontal
            make.spacing = 0
            make.distribution = .fillEqually
        }

        [favouritesLabel, recentLabel].forEach { label in
            label.do { make in
                make.font = UIFont.CustomFont.footnoteRegular
            }
        }

        favouritesUnderView.do { make in
            make.backgroundColor = UIColor.colorsSecondary
            make.isHidden = false
        }

        recentUnderView.do { make in
            make.backgroundColor = UIColor.colorsSecondary
        }

        favouritesLabel.text = L.favourites()
        recentLabel.text = L.recentViews()
        favouritesLabel.textAlignment = .center
        recentLabel.textAlignment = .center

        favouritesView.addSubviews(favouritesLabel, favouritesUnderView)
        recentView.addSubviews(recentLabel, recentUnderView)

        containerStackView.addArrangedSubviews(
            [favouritesView, recentView]
        )
        mainContainerView.addSubviews(containerStackView)
        addSubview(mainContainerView)

        let tapGestureRecognizers = [
            UITapGestureRecognizer(target: self, action: #selector(favouritesTapped)),
            UITapGestureRecognizer(target: self, action: #selector(recentTapped))
        ]

        favouritesView.addGestureRecognizer(tapGestureRecognizers[0])
        recentView.addGestureRecognizer(tapGestureRecognizers[1])

        views = [favouritesView, recentView]
        updateViewsAppearance()
    }

    private func setupConstraints() {
        mainContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        [favouritesLabel, recentLabel].forEach { label in
            label.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().inset(12)
            }
        }

        [favouritesUnderView, recentUnderView].forEach { label in
            label.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }

        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(54)
        }

        [favouritesView, recentView].forEach { view in
            view.snp.makeConstraints { make in
                make.height.equalTo(containerStackView.snp.height)
            }
        }
    }

    @objc private func favouritesTapped() {
        selectedIndex = 0
    }

    @objc private func recentTapped() {
        selectedIndex = 1
    }

    private func updateViewsAppearance() {
        for (index, view) in views.enumerated() {
            let isSelected = index == selectedIndex

            if let label = view.subviews.first(where: { $0 is UILabel }) as? UILabel {
                label.textColor = isSelected ? UIColor.colorsSecondary : UIColor.textInactive
            }

            if let underView = view.subviews.first(where: { $0 == favouritesUnderView || $0 == recentUnderView }) {
                underView.isHidden = !isSelected
            }
        }

        delegate?.didSelect(at: selectedIndex)
    }

    func configure(selectedIndex: Int) {
        guard selectedIndex >= 0 && selectedIndex < views.count else {
            fatalError("Invalid index provided for PersonnelSelectionView configuration")
        }
        self.selectedIndex = selectedIndex
    }
}
