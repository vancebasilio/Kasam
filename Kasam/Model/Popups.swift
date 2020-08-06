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
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
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

    func missingFieldsPopup(title: String, description: String, image: UIImage, buttonText: String) {
        var attributes: EKAttributes
        attributes = EKAttributes.centerFloat
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.white), EKColor(UIColor.white)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
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
        let finalTitle = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 23, weight: .bold), color: EKColor(.colorFive), alignment: .center, displayMode: .light))
        let finalDescription = EKProperty.LabelContent(text: description, style: .init(font: UIFont.systemFont(ofSize: 17, weight: .semibold), color: EKColor(.darkGray), alignment: .center, displayMode: .light))
        let button = EKProperty.ButtonContent(label: .init(text: buttonText, style: .init(font: UIFont.systemFont(ofSize: 16, weight: .semibold), color: EKColor(.white),displayMode: .light)), backgroundColor: EKColor(.colorFour), highlightedBackgroundColor: EKColor(UIColor.colorFive).with(alpha: 0.05), displayMode: .light)
        let message = EKPopUpMessage(themeImage: themeImage, title: finalTitle, description: finalDescription, button: button) {
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
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
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
            noOfRows = 4
            viewController.popupType = "userOptions"
        } else if type == "categoryOptions" {
            noOfRows = Icons.categoryIcons.count
            viewController.popupType = "categoryOptions"
        }
        attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: CGFloat(55 * (noOfRows + 2))))
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func showTrophiesPopup(kasamID: String?) {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        var height = CGFloat(40)        //Badges Title height
        if kasamID == nil {
            //For Profile View page (lists all trophies)
            if SavedData.trophiesAchieved.count != 0 {
                height += CGFloat((SavedData.trophiesCount + SavedData.trophiesAchieved.count + 1) * 40)
            } else {
                height += CGFloat(80)
            }
        } else {
            //For specific Kasam
            if SavedData.trophiesAchieved[kasamID!] != nil {
                height += CGFloat((SavedData.trophiesAchieved[kasamID!]?.kasamTrophies.count ?? 0) + 2) * 40
            } else {
                height += CGFloat(80)
            }
        }
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.9), height: .constant(value: height))
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        
        let viewController = TrophiesAchieved()
        viewController.kasamID = kasamID
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func showOptionsPopup(kasamID: String?, title: String?, subtitle: String?, text: String?, type: String, button: String, completion:@escaping () -> ()) {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.8), height: .intrinsic)
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        
        let vc = OptionsPopupController()
        vc.transfer = (kasamID, title, subtitle, text, type, button)
        var buttonPressedObserver: NSObjectProtocol?
        buttonPressedObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "DoneButtonPressed"), object: nil, queue: OperationQueue.main) {(notification) in
            completion()
            NotificationCenter.default.removeObserver(buttonPressedObserver as Any)
        }
        SwiftEntryKit.display(entry: vc, using: attributes)
    }

    func showGroupUserSearch(groupID: String, completion:@escaping () -> ()) {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .none
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.8), height: .constant(value: 400))
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        
        let vc = GroupSearchController()
        SwiftEntryKit.display(entry: vc, using: attributes)
    }

    func showProcessingNote() {
        var attributes: EKAttributes
        attributes = .topNote
        attributes.displayMode = .light
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity
        attributes.popBehavior = .animated(animation: .translation)
        attributes.entryBackground = .color(color: EKColor(UIColor.colorFour))
        attributes.statusBar = .light
        let text = "Looks like you're not connect to the internet"
        let style = EKProperty.LabelStyle(
            font: UIFont.systemFont(ofSize: 15, weight: .medium),
            color: .white,
            alignment: .center,
            displayMode: .light
        )
        let labelContent = EKProperty.LabelContent(
            text: text,
            style: style
        )
        let contentView = EKProcessingNoteMessageView(
            with: labelContent,
            activityIndicator: .white
        )
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    func saveKasamPopup(level: Int, completion:@escaping (Int) -> ()) {
        var attributes: EKAttributes
        attributes = .centerFloat
        attributes.displayMode = .light
        attributes.windowLevel = .alerts
        attributes.displayDuration = .infinity
        attributes.hapticFeedbackType = .success
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .disabled
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.entranceAnimation = .init(scale: .init(from: 0.9, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)), fade: .init(from: 0, to: 1, duration: 0.3))
        attributes.exitAnimation = .init(fade: .init(from: 1, to: 0, duration: 0.2))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 5))
        attributes.positionConstraints.maxSize = .init(width: .ratio(value: 0.7), height: .intrinsic)
        
        let goodLabelStyle = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: EKColor(UIColor.colorFive), displayMode: .light)
        let badLabelStyle = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: EKColor(UIColor.darkGray), displayMode: .light)
        
        let firstButton = EKProperty.ButtonContent(label: EKProperty.LabelContent(text: "Save Kasam", style: goodLabelStyle), backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.colorFour), displayMode: .light) {completion(0); SwiftEntryKit.dismiss()}
        let secondButton = EKProperty.ButtonContent(label: EKProperty.LabelContent(text: "Keep Editing", style: goodLabelStyle), backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.colorFour), displayMode: .light) {completion(1); SwiftEntryKit.dismiss()}
        let badButton = EKProperty.ButtonContent(label: EKProperty.LabelContent(text: "Discard Kasam", style: badLabelStyle), backgroundColor: .clear, highlightedBackgroundColor: EKColor(UIColor.colorFour), displayMode: .light) {completion(2); SwiftEntryKit.dismiss()}
        
        // Generate the content
        var buttonList: [EKProperty.ButtonContent]
        var title = "You have unsaved progress"
        var description = "Are you sure you want to exit without saving first?"
        switch level {
            case 0: buttonList = [badButton]
            case 1:
                buttonList = [secondButton, badButton]
                title = "Your Kasam isn't complete"
                description = "Do you want to keep working on it?"
            case 2: buttonList = [firstButton, secondButton, badButton]
            default: buttonList = [badButton]
        }
        
        let titleLabel = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 18, weight: .medium), color: .black, alignment: .center,displayMode: .light))
        let descriptionLabel = EKProperty.LabelContent(text: description, style: .init(font: UIFont.systemFont(ofSize: 14, weight: .light), color: .black, alignment: .center, displayMode: .light))
        let simpleMessage = EKSimpleMessage(title: titleLabel, description: descriptionLabel)
        
        let buttonsBarContent = EKProperty.ButtonBarContent(with: buttonList, separatorColor: EKColor(UIColor.lightGray), displayMode: .light, expandAnimatedly: false)
        let contentView = EKAlertMessageView(with: EKAlertMessage(simpleMessage: simpleMessage,buttonBarContent: buttonsBarContent))
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    func addKasamPopup(kasamID: String, new: Bool, duration: Int, fullView: Bool) {
        var attributes: EKAttributes
        attributes = .bottomFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.white), EKColor(UIColor.white)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .edgeCrossingDisabled(swipeable: true)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: EKColor(UIColor.colorFour), opacity: 0.6, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        if fullView == true {
            attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: 500))
        } else {
            attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: 300))
        }
        attributes.positionConstraints.verticalOffset = 0
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        let vC = AddKasamController()
        vC.kasamID = kasamID
        vC.repeatDuration = duration
        vC.new = new
        vC.fullView = fullView
        SwiftEntryKit.display(entry: vC, using: attributes)
    }

    func changeDisplayNamePopup(completion:@escaping (Bool) -> ()) {
        let style: FormStyle = .light
        var attributes = FormFieldPresetFactory.attributes()
        attributes.entryBackground = .color(color: EKColor(UIColor.white))
        let titleStyle = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 18, weight: .semibold), color: EKColor(UIColor.darkGray), alignment: .center, displayMode: .light)
        let title = EKProperty.LabelContent(text: "Change Display Name", style: titleStyle)
        let textFields = FormFieldPresetFactory.fields(by: [.motivation], style: style)
        let button = EKProperty.ButtonContent(label: .init(text: "Continue", style: style.buttonTitle), backgroundColor: style.buttonBackground, highlightedBackgroundColor: style.buttonBackground.with(alpha: 0.8), displayMode: .light, accessibilityIdentifier: "continueButton") {
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = textFields[0].textContent
            changeRequest?.commitChanges {(error) in
              completion(true)
            }
            DBRef.currentUser.child("Name").setValue(textFields[0].textContent)
            SwiftEntryKit.dismiss()
        }
        let contentView = EKFormMessageView(with: title, textFieldsContent: textFields, buttonContent: button)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
