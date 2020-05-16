//
//  ErrorMessages.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-26.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import SwiftEntryKit
import Firebase

    //BOTTOM FLOAT CELL----------------------------------------------------------------------------------------
    func floatCellSelected(title: String, description: String) {
        var attributes: EKAttributes
        attributes = .topFloat
        attributes.displayMode = .light
        attributes.hapticFeedbackType = .success
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.colorFour), EKColor(UIColor.colorFive)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.entryInteraction = .delayExit(by: 3)
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.statusBar = .dark
        attributes.positionConstraints.maxSize = .init(width: .intrinsic,height: .intrinsic)
        let title = title
        let desc = description
        let image = "paper-plane-light"
        showNotificationMessage(attributes: attributes, title: title, desc: desc, textColor: .white, imageName: image)
    }

    // Bumps a notification structured entry
    func showNotificationMessage(attributes: EKAttributes, title: String, desc: String, textColor: EKColor, imageName: String? = nil) {
        let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 16, weight: .bold), color: textColor, displayMode: .light), accessibilityIdentifier: "title")
        let description = EKProperty.LabelContent(text: desc, style: .init(font: UIFont.systemFont(ofSize: 15, weight: .light), color: textColor, displayMode: .light), accessibilityIdentifier: "description")
        var image: EKProperty.ImageContent?
        if let imageName = imageName {
            image = EKProperty.ImageContent(image: UIImage(named: imageName)!.withRenderingMode(.alwaysTemplate), displayMode: .light, size: CGSize(width: 35, height: 35), tint: textColor, accessibilityIdentifier: "thumbnail")
        }
        let simpleMessage = EKSimpleMessage(image: image, title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
        let contentView = EKNotificationMessageView(with: notificationMessage)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    //POPUP CONFIRMATION---------------------------------------------------------------------------

    func showPopupConfirmation(title: String, description: String, image: UIImage, buttonText: String, completion:@escaping (Bool) -> ()) {
        var attributes: EKAttributes
        attributes = EKAttributes.centerFloat
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.colorFour), EKColor(UIColor.colorFour.darker)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 100.0/255.0, alpha: 0.3)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8))
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.roundCorners = .all(radius: 20)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 0.7, initialVelocity: 0)), scale: .init(from: 0.7, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.2))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
        attributes.positionConstraints.maxSize = .init(width: .intrinsic, height: .intrinsic)
        attributes.statusBar = .dark
        
        let image = image
        let title = title
        let description = description
        var themeImage: EKPopUpMessage.ThemeImage?
        themeImage = EKPopUpMessage.ThemeImage(image: EKProperty.ImageContent(image: image, displayMode: .light, size: CGSize(width: 60, height: 60), tint: .white, contentMode: .scaleAspectFit))
        let finalTitle = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 23, weight: .bold), color: .white, alignment: .center, displayMode: .light))
        let finalDescription = EKProperty.LabelContent(text: description, style: .init(font: UIFont.systemFont(ofSize: 17, weight: .semibold), color: .white, alignment: .center, displayMode: .light))
        let button = EKProperty.ButtonContent(label: .init(text: buttonText, style: .init(font: UIFont.systemFont(ofSize: 16, weight: .semibold), color: EKColor(UIColor.colorFive),displayMode: .light)), backgroundColor: .white, highlightedBackgroundColor: EKColor(UIColor.colorFive).with(alpha: 0.05), displayMode: .light)
        let message = EKPopUpMessage(themeImage: themeImage, title: finalTitle, description: finalDescription, button: button) {
            completion(true)
            SwiftEntryKit.dismiss()
        }
        let contentView = EKPopUpMessageView(with: message)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    //USER OPTIONS---------------------------------------------------------------------------------------------

    func showBottomPopup(type: String) {
        var attributes: EKAttributes
        attributes = .bottomFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 100.0/255.0, alpha: 0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.safeArea = .empty(fillSafeArea: true)
        attributes.statusBar = .dark
        let viewController = UserOptionsController()
        
        var noOfRows = 0
        if type == "userOptions" {
            noOfRows = 3
            viewController.popupType = "userOptions"
        } else if type == "categoryOptions" {
            noOfRows = Icons.categoryIcons.count
            viewController.popupType = "categoryOptions"
        }
        attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: CGFloat(55 * (noOfRows + 2))))
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func showCenterPopup(kasamID: String?) {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor.black).with(alpha: 0.4))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        var height = CGFloat(35)        //Badges Title height
        if kasamID == nil {
            height += CGFloat(SavedData.badgeSubCatCount * 40)
        } else {
            if SavedData.kasamDict[kasamID!] != nil {
                height += CGFloat((SavedData.badgesAchieved[SavedData.kasamDict[kasamID!]!.kasamName]?.count ?? 0) + 2) * 40
            } else {
                height += CGFloat(80)
            }
        }
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.9), height: .constant(value: height))
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        
        let viewController = BadgesAchieved()
        viewController.kasamID = kasamID
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func showAlertView(completion:@escaping (Int) -> ()) {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.windowLevel = .alerts
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .success
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .disabled
        attributes.screenBackground = .color(color: EKColor(UIColor.black).with(alpha: 0.4))
        attributes.entryBackground = .color(color: .white)
        attributes.entranceAnimation = .init(scale: .init(from: 0.9, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)), fade: .init(from: 0, to: 1, duration: 0.3))
        attributes.exitAnimation = .init(fade: .init(from: 1, to: 0, duration: 0.2))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 5))
        attributes.positionConstraints.maxSize = .init(width: .ratio(value: 0.7), height: .intrinsic)
        let title = EKProperty.LabelContent(text: "You have unsaved progress", style: .init(font: UIFont.systemFont(ofSize: 18, weight: .medium), color: .black, alignment: .center,displayMode: .light))
        let text = "Are you sure you want to exit without saving first?"
        let description = EKProperty.LabelContent(text: text, style: .init(font: UIFont.systemFont(ofSize: 14, weight: .light), color: .black, alignment: .center, displayMode: .light))
        let simpleMessage = EKSimpleMessage(title: title, description: description)
        let buttonFont = UIFont.systemFont(ofSize: 15, weight: .medium)
        
        let firstGoodButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(UIColor.colorFive), displayMode: .light)
        let firstGoodButtonLabel = EKProperty.LabelContent(text: "SAVE KASAM", style: firstGoodButtonLabelStyle)
        let firstGoodButton = EKProperty.ButtonContent(label: firstGoodButtonLabel, backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.colorFour), displayMode: .light) {
                completion(0)
                SwiftEntryKit.dismiss()
        }
        let secondGoodButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(UIColor.colorFive), displayMode: .light)
        let secondGooddButtonLabel = EKProperty.LabelContent(text: "KEEP EDITING", style: secondGoodButtonLabelStyle)
        let secondGoodButton = EKProperty.ButtonContent(label: secondGooddButtonLabel, backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.colorFour), displayMode: .light) {
                completion(1)
                SwiftEntryKit.dismiss()
        }
        let badButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: EKColor(UIColor.darkGray), displayMode: .light)
        let badButtonLabel = EKProperty.LabelContent(text: "DISCARD KASAM", style: badButtonLabelStyle)
        let badButton = EKProperty.ButtonContent(label: badButtonLabel, backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.colorFour), displayMode: .light) {
                completion(2)
                SwiftEntryKit.dismiss()
        }
        
        // Generate the content
        let buttonsBarContent = EKProperty.ButtonBarContent(with: firstGoodButton, secondGoodButton, badButton, separatorColor: EKColor(UIColor.lightGray), displayMode: .light, expandAnimatedly: false)
        let contentView = EKAlertMessageView(with: EKAlertMessage(simpleMessage: simpleMessage,buttonBarContent: buttonsBarContent))
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }


    //ADD KASAM---------------------------------------------------------------------------------------------
    func addKasamPopup(kasamID: String, new: Bool, timelineDuration: Int?) {
        var attributes: EKAttributes
        attributes = .bottomFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 0, alpha: 0.6)))
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.white), EKColor(UIColor.white)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .edgeCrossingDisabled(swipeable: true)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: EKColor(UIColor.colorFour), opacity: 0.6, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: 380))
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        let viewController = AddKasamController()
        viewController.kasamID = kasamID
        viewController.new = new
        viewController.timelineDuration = timelineDuration
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func changeMotivationPopup(motivationID: String, completion:@escaping (Bool) -> ()) {
        let style: FormStyle = .light
        let attributes = FormFieldPresetFactory.attributes()
        let titleStyle = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 15), color: .standardContent, alignment: .center, displayMode: .light)
        let title = EKProperty.LabelContent(text: "Add your motivation!", style: titleStyle)
        let textFields = FormFieldPresetFactory.fields(by: [.motivation], style: style)
        let button = EKProperty.ButtonContent(label: .init(text: "Continue", style: style.buttonTitle), backgroundColor: style.buttonBackground, highlightedBackgroundColor: style.buttonBackground.with(alpha: 0.8), displayMode: .light, accessibilityIdentifier: "continueButton") {
            let newMotivation = Database.database().reference().child("Users").child((Auth.auth().currentUser?.uid)!).child("Motivation")
            if motivationID == "" {
                newMotivation.childByAutoId().setValue(textFields[0].textContent) {(error, ref) -> Void in
                    completion(true)
                }
            } else if motivationID != "" {
                newMotivation.child(motivationID).setValue(textFields[0].textContent) {(error, ref) -> Void in
                    completion(true)
                }
            }
            SwiftEntryKit.dismiss()
        }
        let contentView = EKFormMessageView(with: title, textFieldsContent: textFields, buttonContent: button)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }