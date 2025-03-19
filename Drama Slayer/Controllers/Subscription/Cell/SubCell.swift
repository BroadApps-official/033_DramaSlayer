import UIKit

class SubCell: UICollectionViewCell {
    static let identifier = "SubCell"
    
    private let firstLabel = UILabel()
    private let secondLabel = UILabel()
    private let priceStackView = UIStackView()
    private let circleImageView = UIImageView()
    private let containerView = UIView()

    var dynamicTitle: String?
    var dynamicPrice: String?
    
    private let bestLabel = UILabel()
    private let bestView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        containerView.isUserInteractionEnabled = false
        circleImageView.image = R.image.sub_cell_circle()?.withRenderingMode(.alwaysTemplate)
        circleImageView.tintColor = UIColor.textInactive

        containerView.do { make in
            make.backgroundColor = UIColor.bgTertiary
            make.layer.cornerRadius = 12
        }

        firstLabel.do { make in
            make.text = "Weekly · $9.99"
            make.font = UIFont.CustomFont.caption1Regular
            make.textColor = UIColor.textTertiary
            make.textAlignment = .left
        }

        secondLabel.do { make in
            make.text = "$9.99 / week"
            make.font = UIFont.CustomFont.bodyRegular
            make.textColor = UIColor.textMain
            make.textAlignment = .left
        }

        priceStackView.do { make in
            make.axis = .vertical
            make.spacing = 0
            make.alignment = .leading
            make.distribution = .fill
        }
        
        bestLabel.do { make in
            make.text = L.bestOffer().uppercased()
            make.textAlignment = .center
            make.font = UIFont.CustomFont.caption1Regular
            make.textColor = UIColor.textMain
        }

        bestView.do { make in
            make.backgroundColor = UIColor.colorsSecondary
            make.layer.cornerRadius = 6
        }

        priceStackView.addArrangedSubviews([firstLabel, secondLabel])
        bestView.addSubviews(bestLabel)
        addSubviews(circleImageView, containerView, priceStackView, bestView)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        circleImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }

        priceStackView.snp.makeConstraints { make in
            make.leading.equalTo(circleImageView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        bestView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(12)
            make.height.equalTo(24)
        }

        bestLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(8)
        }
    }
    
    func configureAppearance(isSelected: Bool) {
        let borderColor: CGColor = isSelected ? UIColor.colorsSecondary.cgColor : UIColor.clear.cgColor
        let borderWidth: CGFloat = isSelected ? 1 : 0

        circleImageView.tintColor = isSelected ? UIColor.colorsSecondary : UIColor.textInactive
        containerView.layer.borderColor = borderColor
        containerView.layer.borderWidth = borderWidth
    }
    
    func configure(name: String, price: String, weeklyPrice: String?, isFirst: Bool) {
        firstLabel.text = "\(name.capitalized) · \(price)"
        if let weeklyPrice = weeklyPrice {
            secondLabel.text = "\(weeklyPrice) / week"
        } else {
            secondLabel.text = "N/A / week" 
        }
        bestView.isHidden = !isFirst
    }
}
