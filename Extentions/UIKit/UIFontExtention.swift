import UIKit

extension UIFont {
    struct CustomFont {
        static let largeTitleBold = UIFont.systemFont(ofSize: 34, weight: .bold)
        static let largeTitleRegular = UIFont.systemFont(ofSize: 34)
        
        static let title1Regular = UIFont.systemFont(ofSize: 28)
        static let title1Bold = UIFont.systemFont(ofSize: 28, weight: .bold)
        
        static let title2Regular = UIFont.systemFont(ofSize: 22)
        static let title2Bold = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        static let title3Regular = UIFont.systemFont(ofSize: 20)
        static let title3Semibold = UIFont.systemFont(ofSize: 20, weight: .semibold)
        
        static let headlineRegular = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let headlineItalic: UIFont = {
            let descriptor = UIFont.systemFont(ofSize: 17, weight: .semibold).fontDescriptor
                .withSymbolicTraits([.traitBold, .traitItalic])
            return UIFont(descriptor: descriptor ?? UIFontDescriptor(), size: 17)
        }()
        
        static let bodyRegular = UIFont.systemFont(ofSize: 17)
        static let bodySemibold = UIFont.systemFont(ofSize: 17, weight: .semibold)
        static let bodyItalic: UIFont = {
            let descriptor = UIFont.systemFont(ofSize: 17, weight: .regular).fontDescriptor
                .withSymbolicTraits([.traitBold, .traitItalic])
            return UIFont(descriptor: descriptor ?? UIFontDescriptor(), size: 17)
        }()        
        
        static let subheadlineRegular = UIFont.systemFont(ofSize: 15)
        static let subheadlineSemibold = UIFont.systemFont(ofSize: 15, weight: .semibold)
        static let subheadlineItalic: UIFont = {
            let descriptor = UIFont.systemFont(ofSize: 15, weight: .regular).fontDescriptor
                .withSymbolicTraits([.traitBold, .traitItalic])
            return UIFont(descriptor: descriptor ?? UIFontDescriptor(), size: 15)
        }()
        
        static let footnoteSemibold = UIFont.systemFont(ofSize: 13, weight: .semibold)
        static let footnoteRegular = UIFont.systemFont(ofSize: 13)
        
        static let caption1Regular = UIFont.systemFont(ofSize: 12)

        static let caption2Regular = UIFont.systemFont(ofSize: 11)

        static let bodyEmphasized = UIFont.systemFont(ofSize: 17, weight: .semibold)        
    }
}
