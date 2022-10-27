import Foundation
import UIKit

/// 使用 `UITextView` 实现的 `UILabel`。
///
/// 此类型用于构建新的组件，亦可直接使用。默认提供的功能包括：
///
/// - 与 `UILabel` 完全相同的显示风格和行为，以及绝大部分 `UILabel` 的属性。
/// - 参与自动布局，包括 Storyboard 中预览和自动布局。
/// - 子类声明实现 `UITextViewDelegate` 时，事件回调优先派发给子类，外部设置的 `delegate` 只能接收到子类委托实现派发的事件。
/// - 关闭 `isSelectable` 时仍然允许点击富文本链接。
///
/// 使用和维护须知：
///
/// - 不允许为 ``UITextLabel`` 基类实现或扩展 `UITextViewDelegate`，因为子类将无法重载或实现基类未实现的可选委托回调。如果子类决定实现
///   `UITextViewDelegate`，需注意未实现的回调也无法被下一级继承实现。
/// - 除非遇到与 `UILabel` 不一致场景，不允许修改基类 ``loadView()`` 中的初始化代码。``UITextLabel`` 默认模拟 `UILabel` 行为。
/// - ``loadView()`` 中访问属性和方法必须调用 `super`，避免初始化时与自定义行为重载冲突或导致递归；其他方法中必须调用
///   `self`，以遵循子类期待的自定义行为。
/// - ``UITextLabel`` 基类中的所有重载必须声明为 `open`。除非无扩展或自定义可能性，新属性和方法强烈建议声明为 `open`。
@IBDesignable
open class UITextLabel: UITextView {
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.loadView()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.loadView()
    }

    open func loadView() {
        super.textContainerInset = .zero
        super.textContainer.lineFragmentPadding = .zero
        super.textContainer.lineBreakMode = .byTruncatingTail
        super.isEditable = false
        super.isScrollEnabled = false

        // 必须是 true 以支持超链接，副作用在下方「选取」代码段规避和控制。
        super.isSelectable = true

        // 当子类实现 UITextViewDelegate 时优先回调子类，副作用在下方「委托」代码段规避和控制。
        if let delegate = self as? UITextViewDelegate {
            super.delegate = delegate
        }
    }

    // MARK: - Auto Layout

    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.loadView()
    }

    override open var contentSize: CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override open var intrinsicContentSize: CGSize {
        self.contentSize
    }

    // MARK: - 模拟 UILabel

    open var numberOfLines: Int {
        get { self.textContainer.maximumNumberOfLines }
        set { self.textContainer.maximumNumberOfLines = newValue }
    }

    open var lineBreakMode: NSLineBreakMode {
        get { self.textContainer.lineBreakMode }
        set { self.textContainer.lineBreakMode = newValue }
    }

    // MARK: - 委托

    private var _delegate: UITextViewDelegate?

    override open var delegate: UITextViewDelegate? {
        get {
            if self is UITextViewDelegate {
                return self._delegate
            }
            return super.delegate
        }
        set {
            if self is UITextViewDelegate {
                self._delegate = newValue
                return
            }
            super.delegate = newValue
        }
    }

    override open func forwardingTarget(for selector: Selector!) -> Any? {
        if self is UITextViewDelegate, self._delegate?.responds(to: selector) == true {
            return self._delegate
        }
        return super.forwardingTarget(for: selector)
    }

    override open func responds(to selector: Selector!) -> Bool {
        if self is UITextViewDelegate, self._delegate?.responds(to: selector) == true {
            return true
        }
        return super.responds(to: selector)
    }

    // MARK: - 选取

    private var _isSelectable = false

    override open var isSelectable: Bool {
        get { self._isSelectable }
        set { self._isSelectable = newValue }
    }

    override open func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !self.isSelectable else {
            return super.point(inside: point, with: event)
        }

        // Enable links while preventing text selection:
        // https://stackoverflow.com/a/44878203
        guard let position = self.closestPosition(to: point) else {
            return false
        }
        guard let range = self.tokenizer.rangeEnclosingPosition(position, with: .character,
                                                                inDirection: .layout(.left)) else {
            return false
        }
        let startIndex = self.offset(from: beginningOfDocument, to: range.start)
        return self.attributedText.attribute(.link, at: startIndex, effectiveRange: nil) != nil
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // Edit menu follows selectable.
        self._isSelectable
    }
}
