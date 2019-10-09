//
//  PopupForm.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-10-08.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import SwiftEntryKit

final class FormFieldPresetFactory {
    
    private static var displayMode: EKAttributes.DisplayMode {
        return .light
    }
    
    class func email(placeholderStyle: EKProperty.LabelStyle,
                     textStyle: EKProperty.LabelStyle,
                     separatorColor: EKColor,
                     style: FormStyle) -> EKProperty.TextFieldContent {
        let emailPlaceholder = EKProperty.LabelContent(
            text: "Email Address",
            style: placeholderStyle
        )
        return .init(keyboardType: .emailAddress,
                     placeholder: emailPlaceholder,
                     tintColor: style.textColor,
                     displayMode: displayMode,
                     textStyle: textStyle,
                     leadingImage: UIImage(named: "ic_mail_light")!.withRenderingMode(.alwaysTemplate),
                     bottomBorderColor: separatorColor,
                     accessibilityIdentifier: "emailTextField")
    }
    
    class func fullName(placeholderStyle: EKProperty.LabelStyle,
                        textStyle: EKProperty.LabelStyle,
                        separatorColor: EKColor,
                        style: FormStyle) -> EKProperty.TextFieldContent {
        let fullNamePlaceholder = EKProperty.LabelContent(
            text: "Full Name",
            style: placeholderStyle
        )
        return .init(keyboardType: .namePhonePad,
                     placeholder: fullNamePlaceholder,
                     tintColor: style.textColor,
                     displayMode: displayMode,
                     textStyle: textStyle,
                     leadingImage: UIImage(named: "ic_user_light")!.withRenderingMode(.alwaysTemplate),
                     bottomBorderColor: separatorColor,
                     accessibilityIdentifier: "nameTextField")
    }
    
    class func motivation(placeholderStyle: EKProperty.LabelStyle, textStyle: EKProperty.LabelStyle, separatorColor: EKColor, style: FormStyle) -> EKProperty.TextFieldContent {
        let motivationPlaceholder = EKProperty.LabelContent(text: "Motivation Text", style: placeholderStyle)
        return .init(keyboardType: .namePhonePad,
                     placeholder: motivationPlaceholder,
                     tintColor: style.textColor,
                     displayMode: displayMode,
                     textStyle: textStyle,
                     leadingImage: UIImage(named: "ic_coffee_light")!.withRenderingMode(.alwaysTemplate),
                     bottomBorderColor: separatorColor,
                     accessibilityIdentifier: "motivationTextField")
    }
    
    class func mobile(placeholderStyle: EKProperty.LabelStyle,
                      textStyle: EKProperty.LabelStyle,
                      separatorColor: EKColor,
                      style: FormStyle) -> EKProperty.TextFieldContent {
        let mobilePlaceholder = EKProperty.LabelContent(
            text: "Mobile Phone",
            style: placeholderStyle
        )
        return .init(keyboardType: .decimalPad,
                     placeholder: mobilePlaceholder,
                     tintColor: style.textColor,
                     displayMode: displayMode,
                     textStyle: textStyle,
                     leadingImage: UIImage(named: "ic_phone_light")!.withRenderingMode(.alwaysTemplate),
                     bottomBorderColor: separatorColor,
                     accessibilityIdentifier: "mobilePhoneTextField")
    }
    
    class func password(placeholderStyle: EKProperty.LabelStyle,
                        textStyle: EKProperty.LabelStyle,
                        separatorColor: EKColor,
                        style: FormStyle) -> EKProperty.TextFieldContent {
        let passwordPlaceholder = EKProperty.LabelContent(text: "Password",
                                                          style: placeholderStyle)
        return .init(keyboardType: .namePhonePad,
                     placeholder: passwordPlaceholder,
                     tintColor: style.textColor,
                     displayMode: displayMode,
                     textStyle: textStyle,
                     isSecure: true,
                     leadingImage: UIImage(named: "ic_lock_light")!.withRenderingMode(.alwaysTemplate),
                     bottomBorderColor: separatorColor,
                     accessibilityIdentifier: "passwordTextField")
    }
    
    struct TextFieldOptionSet: OptionSet {
        let rawValue: Int
        static let motivation = TextFieldOptionSet(rawValue: 1 << 0)
        static let fullName = TextFieldOptionSet(rawValue: 1 << 0)
        static let mobile = TextFieldOptionSet(rawValue: 1 << 1)
        static let email = TextFieldOptionSet(rawValue: 1 << 2)
        static let password = TextFieldOptionSet(rawValue: 1 << 3)
    }
    
    class func fields(by set: TextFieldOptionSet, style: FormStyle) -> [EKProperty.TextFieldContent] {
        var array: [EKProperty.TextFieldContent] = []
        let placeholderStyle = style.placeholder
        let textStyle = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 15), color: .standardContent, displayMode: displayMode)
        let separatorColor = style.separator
        if set.contains(.motivation) {
            array.append(motivation(placeholderStyle: placeholderStyle,
                                    textStyle: textStyle,
                                    separatorColor: separatorColor,
                                    style: style))
        }
//        if set.contains(.fullName) {
//            array.append(fullName(placeholderStyle: placeholderStyle,
//                                  textStyle: textStyle,
//                                  separatorColor: separatorColor,
//                                  style: style))
//        }
        if set.contains(.mobile) {
            array.append(mobile(placeholderStyle: placeholderStyle,
                                textStyle: textStyle,
                                separatorColor: separatorColor,
                                style: style))
        }
        if set.contains(.email) {
            array.append(email(placeholderStyle: placeholderStyle,
                               textStyle: textStyle,
                               separatorColor: separatorColor,
                               style: style))
        }
        if set.contains(.password) {
            array.append(password(placeholderStyle: placeholderStyle,
                                  textStyle: textStyle,
                                  separatorColor: separatorColor,
                                  style: style))
        }
        return array
    }
}

enum FormStyle {
    case light
    case metallic
    
    var buttonTitle: EKProperty.LabelStyle {
        return .init(
            font: UIFont.systemFont(ofSize: 15),
            color: buttonTitleColor
        )
    }
    
    var textColor: EKColor {
        switch self {
        case .metallic:
            return .white
        case .light:
            return .standardContent
        }
    }
    
    var buttonTitleColor: EKColor {
        switch self {
        case .metallic:
            return .black
        case .light:
            return .white
        }
    }
    
    var buttonBackground: EKColor {
        switch self {
        case .metallic:
            return .white
        case .light:
            return .black
        }
    }
    
    var placeholder: EKProperty.LabelStyle {
        let font = UIFont.systemFont(ofSize: 15)
        switch self {
        case .metallic:
            return .init(font: font, color: EKColor.black)
        case .light:
            return .init(font: font, color: EKColor.black)
        }
    }
    
    var separator: EKColor {
        return EKColor.black
    }
}
