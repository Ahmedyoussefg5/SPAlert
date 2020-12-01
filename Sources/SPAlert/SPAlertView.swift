// The MIT License (MIT)
// Copyright © 2020 Ivan Vorobei (varabeis@icloud.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UIKit

open class SPAlertView: UIView {
    
    // MARK: - Views
    
    private var titleLabel: UILabel?
    
    private var subtitleLabel: UILabel?
    
    private var iconView: UIView?
    
    private lazy var backgroundView: UIVisualEffectView = {
        let view: UIVisualEffectView = {
            if #available(iOS 13.0, *) {
                return UIVisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
            } else {
                return UIVisualEffectView(effect: UIBlurEffect(style: .light))
            }
        }()
        view.isUserInteractionEnabled = false
        return view
    }()
    
    weak open var presentWindow: UIWindow? = UIApplication.shared.windows.first
    
    // MARK: - Properties
    
    open var dismissByTap: Bool = true
    
    // MARK: - Initializers
    
    public init(title: String, message: String?, preset: SPAlertIconPreset) {
        super.init(frame: CGRect.zero)
        commonInit()
        layout = SPAlertLayout(for: preset)
        setTitle(title)
        if let message = message {
            setMessage(message)
        }
        setIcon(for: preset)
    }
    
    public init(message: String) {
        super.init(frame: CGRect.zero)
        commonInit()
        layout = SPAlertLayout()
        setMessage(message)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // MARK: Configure
    
    private func setTitle(_ text: String) {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 3
        style.alignment = .center
        label.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: style])
        titleLabel = label
        addSubview(label)
    }
    
    private func setMessage(_ text: String) {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 2
        style.alignment = .center
        label.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: style])
        subtitleLabel = label
        addSubview(label)
    }
    
    private func setIcon(for preset: SPAlertIconPreset) {
        let view = preset.createView()
        self.iconView = view
        addSubview(view)
    }
    
    func commonInit() {
        layer.masksToBounds = true
        layer.cornerRadius = 8
        backgroundColor = .clear
        addSubview(backgroundView)
    }
    
    // MARK: - Present
    
    fileprivate var presentDismissDuration: TimeInterval = 0.2
    fileprivate var presentDismissScale: CGFloat = 0.8
    
    open func present(duration: TimeInterval = 1.5, haptic: SPAlertHaptic = .success, completion: (() -> Void)? = nil) {
        guard let window = self.presentWindow else { return }
        window.addSubview(self)
        
        // Prepare for present
        
        alpha = 0
        setFrame()
        transform = transform.scaledBy(x: self.presentDismissScale, y: self.presentDismissScale)
        
        // Present
        
        UIView.animate(withDuration: presentDismissDuration, animations: {
            self.alpha = 1
            self.transform = CGAffineTransform.identity
        }, completion: { finished in
            if let iconView = self.iconView as? SPAlertIconAnimatable {
                iconView.animate()
            }
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                self.dismiss()
            }
        })
    }
    
    open func dismiss() {
        UIView.animate(withDuration: presentDismissDuration, animations: {
            self.alpha = 0
            self.transform = self.transform.scaledBy(x: self.presentDismissScale, y: self.presentDismissScale)
        }, completion: { finished in
            self.removeFromSuperview()
        })
    }
    
    // MARK: - Layout
    
    open var layout: SPAlertLayout = .init()
    
    fileprivate func setFrame() {
        guard let window = self.presentWindow else { return }
        frame = CGRect.init(x: 0, y: 0, width: 250, height: 250)
        layoutMargins = layout.margins
        sizeToFit()
        center = .init(x: window.frame.midX, y: window.frame.midY)
    }
    
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        layoutSubviews()
        let bottomY = [subtitleLabel, titleLabel, iconView].first(where: { $0 != nil })??.frame.maxY ?? 150
        return CGSize.init(width: 250, height: bottomY + layoutMargins.bottom)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.frame = bounds
        if let iconView = self.iconView {
            iconView.frame = .init(origin: .init(x: 0, y: 63), size: layout.iconSize)
            iconView.center.x = bounds.midX
        }
        if let titleLabel = self.titleLabel {
            layout(
                label: titleLabel,
                x: layoutMargins.left,
                y: iconView == nil ? layoutMargins.top : (iconView?.frame.maxY ?? 0) + layout.spaceBetweenIconAndTitle,
                width: frame.width - layoutMargins.left - layoutMargins.right
            )
        }
        if let subtitleLabel = self.subtitleLabel {
            let yPosition: CGFloat = {
                if let titleLabel = self.titleLabel {
                    return titleLabel.frame.maxY + 4
                } else {
                    return layoutMargins.top
                }
            }()
            layout(
                label: subtitleLabel,
                x: layoutMargins.left,
                y: yPosition,
                width: frame.width - layoutMargins.left - layoutMargins.right
            )
        }
    }
    
    private func layout(label: UILabel, x: CGFloat, y: CGFloat,  width: CGFloat) {
        label.frame = .init(x: x, y: y, width: width, height: label.frame.height)
        label.sizeToFit()
        label.frame = .init(x: x, y: y, width: width, height: label.frame.height)
    }
}