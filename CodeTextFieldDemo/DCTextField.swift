//
//  DCTextField.swift
//  CodeTextFieldDemo
//
//  Created by tezwez on 2020/3/30.
//  Copyright © 2020 tezwez. All rights reserved.
//

import Foundation
import UIKit

@objc protocol DCTextFieldDelegate {
    @objc optional func textFieldDidEndEdit(_ textField: DCTextField) -> Void
    @objc optional func textFieldReturn(_ textField: DCTextField) -> Bool
}
/// 验证码输入框/密码输入框
class DCTextField: UIView {
    
    enum Style {
        case bottomLine
        case border
    }
    private lazy var alphaAnimation: CABasicAnimation = {
        let alpha = CABasicAnimation(keyPath: "opacity")
        alpha.fromValue = 1.0
        alpha.toValue = 0.0
        alpha.duration = 1.0;
        alpha.repeatCount = Float(CGFloat.greatestFiniteMagnitude);
        alpha.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
        return alpha
    }()
    private lazy var cursor: CALayer = {
        let layer = CALayer()
        return layer
    }()
    
    // MARK: - private property
    private var innerText: NSMutableString?
    private var borderWidth: CGFloat = 1
    private var downLineWidth: CGFloat = 0.5
    
    // MARK: - public property
    var delegate: DCTextFieldDelegate?
    var text: String?{
        set{
            innerText = NSMutableString.init(string: newValue ?? "")
            setNeedsDisplay()
        }
        get{
            return innerText as String?
        }
    }
    var font: UIFont = UIFont.systemFont(ofSize: 20){
        didSet{
            setNeedsDisplay()
        }
    }
    
    var color: UIColor = UIColor.darkText{
        didSet{
            setNeedsDisplay()
        }
    }
    var borderColor: UIColor = UIColor.lightGray{
        didSet{
            setNeedsDisplay()
        }
    }
    
    // 配置信息
    var maxTextLength: Int = 6{
        didSet{
            setNeedsDisplay()
        }
    }
    var isSecureTextEntry: Bool = false{
        didSet{
            setNeedsDisplay()
        }
    }
    var style: Style = .border{
        didSet{
            setNeedsDisplay()
        }
    }
    
    var cursorColor: UIColor = .blue{
        didSet{
            cursor.backgroundColor = cursorColor.cgColor
        }
    }
    
    var keyboardType: UIKeyboardType = .asciiCapable
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        innerText = NSMutableString()
        backgroundColor = .white
        cursor.backgroundColor = cursorColor.cgColor
        layer.addSublayer(cursor)
        layer.masksToBounds = true
        setupCursor(nil)
        dismissCursor()
    }
    
}

// MARK: - UIKeyInput
extension DCTextField: UIKeyInput{
    var hasText: Bool {
        return (innerText?.length ?? 0) > 0
    }
    
    func insertText(_ text: String) {
        if text == " " {
            return
        }
        if text == "\n" {
            _ = delegate?.textFieldReturn?(self)
            return
        }
        if text.count > 1 {
            return
        }
        if !isValiateText(text) {
            return
        }
        if (innerText?.length ?? 0) >= maxTextLength {
            return
        }
        
        innerText?.append(text)
        setupCursor(self.text)
        if (innerText?.length == maxTextLength) {
            _ = resignFirstResponder()
        }
        
        setNeedsDisplay()
    }
    
    func deleteBackward() {
        if (innerText?.length ?? 0) == 0 {
            return
        }
        
        let range = NSMakeRange(innerText!.length-1, 1)
        innerText?.deleteCharacters(in: range)
        setupCursor(self.text)
        setNeedsDisplay()
    }
    
    private var returnKeyType: UIReturnKeyType{
        return .next
    }
    
    override var canBecomeFirstResponder: Bool{
        return true
    }
    
    override var canResignFirstResponder: Bool{
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        delegate?.textFieldDidEndEdit?(self)
        dismissCursor()
        return super.resignFirstResponder()
    }
    override func becomeFirstResponder() -> Bool {
        setupCursor(self.text)
        return super.becomeFirstResponder()
    }
    private var autocorrectionType: UITextAutocorrectionType{
        return .no
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !self.isFirstResponder {
            _ = becomeFirstResponder()
        }
    }
    
    private func isValiateText(_ text: String) -> Bool{
        let pattern = "^[a-zA-Z0-9]+$"
        let pre = NSPredicate(format: "SELF MATCHES %@", pattern)
        let length = text.count
        for i in 0..<length{
            let subText = text.subString(start: i, length: 1)
            if !pre.evaluate(with: subText) {
                return false
            }
        }
        
        return true
    }
}

// MARK: - Draw
extension DCTextField{
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        switch style {
        case .border:
            drawBorder(rect)
            drawDownLine(rect)
        case .bottomLine:
            drawBottomLine(rect)
        }
        
        if isSecureTextEntry {
            drawCircle(rect)
        } else {
            drawText(rect)
        }
        
    }
    
    // 画边框
    private func drawBorder(_ rect: CGRect){
        let cornerRadius: CGFloat = 5
        let width = rect.size.width
        let height = rect.size.height
        
        // 设置边框颜色
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setStrokeColor(borderColor.cgColor)
        context?.setLineWidth(borderWidth)
        
        // 上边
        var x = cornerRadius
        var y: CGFloat = 0
        context?.move(to: CGPoint(x: x+borderWidth/2, y: y+borderWidth/2))
        x = width - cornerRadius
        y = 0
        context?.addLine(to: CGPoint(x: x-borderWidth/2, y: y+borderWidth/2))
        
        // 右上角圆弧
        var cpx = width - borderWidth/2.0
        var cpy = 0 + borderWidth/2
        x = width
        y = cornerRadius
        context?.addQuadCurve(to: CGPoint(x: x-borderWidth/2, y: y+borderWidth/2), control: CGPoint(x: cpx, y: cpy))
        
        // 右边
        x = width
        y = height-cornerRadius
        context?.addLine(to: CGPoint(x: x-borderWidth/2, y: y-borderWidth/2))
        
        // 右下圆弧
        cpx = width - borderWidth/2
        cpy = height - borderWidth/2
        x = width - cornerRadius
        y = height
        context?.addQuadCurve(to: CGPoint(x: x-borderWidth/2, y: y - borderWidth/2), control: CGPoint(x: cpx, y: cpy))
        
        // 下边
        x = cornerRadius
        y = height
        context?.addLine(to: CGPoint(x: x+borderWidth/2, y: y-borderWidth/2))
        
        // 左下圆弧
        cpx = 0+borderWidth/2
        cpy = height-borderWidth/2
        x = 0
        y = height - cornerRadius
        context?.addQuadCurve(to: CGPoint(x: x+borderWidth/2.0, y: y-borderWidth/2.0), control: CGPoint(x: cpx, y: cpy))
        
        // 左边
        x = 0
        y = cornerRadius
        context?.addLine(to: CGPoint(x: x+borderWidth/2, y: y+borderWidth/2))
        
        // 左上圆弧
        cpx = 0 + borderWidth/2
        cpy = 0 + borderWidth/2
        x = cornerRadius
        y = 0
        context?.addQuadCurve(to: CGPoint(x: x+borderWidth/2, y: y+borderWidth/2), control: CGPoint(x: cpx, y: cpy))
        context?.strokePath()
        context?.restoreGState()
        
        context?.saveGState()
        context?.setFillColor(UIColor.white.cgColor)
        context?.fillPath()
        context?.restoreGState()
    }
    
    private func drawDownLine(_ rect: CGRect){
        let width = rect.width
        let height = rect.height
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setStrokeColor(borderColor.cgColor)
        context?.setLineWidth(downLineWidth)
        
        let contentWidth = width-borderWidth*2-downLineWidth*CGFloat(maxTextLength-1)
        let itemWidth = contentWidth/CGFloat(maxTextLength)
        for i in 0..<maxTextLength-1 {
            let x = borderWidth + (CGFloat(i+1)*itemWidth+CGFloat(i)*downLineWidth)
            var y: CGFloat = 0
            context?.move(to: CGPoint(x: x, y: y))
            y = height
            context?.addLine(to: CGPoint(x: x, y: y))
            context?.strokePath()
        }
        context?.restoreGState()
    }
    // 下划线
    private func drawBottomLine(_ rect: CGRect){
        let width = rect.width
        let height = rect.height
        let gap: CGFloat = 8
        let left: CGFloat = 4
        let right: CGFloat = 4
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.setStrokeColor(borderColor.cgColor)
        context?.setLineWidth(borderWidth)
        
        
        let bottomLineWidth = (width-left-right-gap*CGFloat(maxTextLength-1))/CGFloat(maxTextLength)
        let y = height-borderWidth/2
        for i in 0..<maxTextLength {
            let x: CGFloat = 0
            let startP = CGPoint(x: x+left+CGFloat(i)*bottomLineWidth+gap*CGFloat(i), y: y)
            let endP = CGPoint(x: x+left+bottomLineWidth*CGFloat(i+1)+gap*CGFloat(i), y: y)
            context?.move(to: startP)
            context?.addLine(to: endP)
            context?.strokePath()
        }
        context?.restoreGState()
    }
    
    // 画圆
    private func drawCircle(_ rect: CGRect){
        let width = rect.width
        let height = rect.height
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.saveGState()
        context?.setFillColor(color.cgColor)
        
        let contentWidth = width-borderWidth*2-downLineWidth*CGFloat(maxTextLength-1)
        let itemWidth = contentWidth/CGFloat(maxTextLength)
        let radius = font.pointSize
        let y = (height-radius)/2
        for i in 0..<(innerText?.length ?? 0) {
            let x = borderWidth+CGFloat(i)*itemWidth+CGFloat(i)*downLineWidth+(itemWidth-radius)/2
            let circleRect = CGRect(x: x, y: y, width: radius, height: radius)
            context?.fillEllipse(in: circleRect)
        }
        context?.restoreGState()
    }
    
    // 写文字
    private func drawText(_ rect: CGRect){
        let width = rect.width
        let height = rect.height
        
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        
        let contentWidth = width-borderWidth*2-downLineWidth*CGFloat(maxTextLength-1)
        let itemWidth = contentWidth/CGFloat(maxTextLength)
        let textSize = sizeForText()
        let y = (height-textSize.height)/2
        
        for i in 0..<(innerText?.length ?? 0) {
            let word = innerText?.substring(with: NSMakeRange(i, 1)) as NSString?
            let x = borderWidth + CGFloat(i)*itemWidth+CGFloat(i)*downLineWidth+(itemWidth-textSize.width)/2
            let textRect = CGRect(x: x, y: y, width: textSize.width, height: textSize.height)
            // 文字居中
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            word?.draw(in: textRect, withAttributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: color, NSAttributedString.Key.paragraphStyle: style])
        }
        context?.restoreGState()
    }
    
    private func sizeForText() -> CGSize{
        let text = "O" as NSString
        let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
        return size
    }
}

extension String{
    ///根据开始位置和长度截取字符串
    public func subString(start:Int, length:Int = -1) -> String {
        var len = length
        if len == -1 {
            len = self.count - start
        }
        let st = self.index(startIndex, offsetBy:start)
        let en = self.index(st, offsetBy:len)
        return String(self[st ..< en])
    }
}

// MARK: - Cursor
extension DCTextField{
    private func setupCursor(_ text: String?){
        cursor.isHidden = false
        cursor.add(alphaAnimation, forKey: "alphaAnimation")
        
        let string = text ?? ""
        
        let width = self.frame.size.width
        let height = self.frame.size.height
        let contentWidth = width-borderWidth*2-downLineWidth*CGFloat(maxTextLength-1)
        let itemWidth = contentWidth/CGFloat(maxTextLength)
        
        let cursorSize = CGSize(width: 1, height: 20)
        let y = (height-cursorSize.height)/2
        var index = string.count
        if index == maxTextLength{
            dismissCursor()
            index = maxTextLength - 1
        }
        let x = borderWidth + CGFloat(index)*itemWidth+CGFloat(index)*downLineWidth+(itemWidth-cursorSize.width)/2
        let textRect = CGRect(x: x, y: y, width: cursorSize.width, height: cursorSize.height)
        cursor.frame = textRect
    }
    
    private func dismissCursor(){
        cursor.isHidden = true
        cursor.removeAllAnimations()
    }
}
