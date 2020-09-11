//
//  ErrorMessages.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-26.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import SwiftEntryKit
import FirebaseAuth

    //FLOAT CELLS----------------------------------------------------------------------------------------
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
        let style = EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 15, weight: .medium), color: .white, alignment: .center, displayMode: .light)
        let labelContent = EKProperty.LabelContent(text: text, style: style)
        let contentView = EKProcessingNoteMessageView(with: labelContent, activityIndicator: .white)
        SwiftEntryKit.display(entry: contentView, using: attributes)
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

    func showCenterPopupConfirmation(title: String, description: String, image: UIImage, buttonText: String, completion:@escaping (Bool) -> ()) {
        var attributes = PopupAttributes.center()
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
        attributes.positionConstraints.maxSize = .init(width: .intrinsic, height: .intrinsic)
        
        var themeImage: EKPopUpMessage.ThemeImage?
        themeImage = EKPopUpMessage.ThemeImage(image: EKProperty.ImageContent(image: image, displayMode: .dark, size: CGSize(width: 60, height: 60), tint: .black, contentMode: .scaleAspectFit))
        let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 23, weight: .bold), color: .black, alignment: .center, displayMode: .light))
        let description = EKProperty.LabelContent(text: description, style: .init(font: UIFont.systemFont(ofSize: 17, weight: .semibold), color: EKColor(UIColor.darkGray), alignment: .center, displayMode: .light))
        let button = EKProperty.ButtonContent(label: .init(text: buttonText, style: .init(font: UIFont.systemFont(ofSize: 16, weight: .semibold), color: .white, displayMode: .light)), backgroundColor: .black, highlightedBackgroundColor: EKColor(UIColor.colorFive).with(alpha: 0.05), displayMode: .light)
        let message = EKPopUpMessage(themeImage: themeImage, title: title, description: description, button: button) {
            completion(true)
            SwiftEntryKit.dismiss()
        }
        let contentView = EKPopUpMessageView(with: message)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    func missingFieldsPopup(title: String, description: String, image: UIImage, buttonText: String) {
        var attributes = PopupAttributes.center()
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

    func showBottomTablePopup(type: String, programKasamArray: [(no: Int, blockID: String, blockName: String)]?) {
        let viewController = TablePopupController()
        var noOfRows = 0
        if type == "changeKasamBlock" {
            noOfRows = programKasamArray?.count ?? 1
        } else if type == "userOptions" {
            noOfRows = 4
        } else if type == "categoryOptions" {
            noOfRows = Icons.categoryIcons.count
        }
        viewController.array = programKasamArray
        viewController.popupType = type
        var attributes = PopupAttributes.bottom()
        attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: CGFloat(55 * (noOfRows + 2))))
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func showBottomNotificationsPopup() {
        let viewController = NotificationsController()
        var attributes = PopupAttributes.bottom()
        attributes.positionConstraints.size = .init(width: .fill, height: .ratio(value: 0.9))
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }
    

    func showBottomButtonPopup(title: String, buttonText: [String], completion:@escaping (Int) -> ()) {
        let viewController = ButtonPopupController()
        viewController.buttonTextArray = buttonText
        viewController.title = title
        var attributes = PopupAttributes.bottom()
        attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: CGFloat(270)))
        var firstButtonObserver: NSObjectProtocol?
        firstButtonObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "FirstButtonPressed"), object: nil, queue: OperationQueue.main) {(notification) in
            completion(0)
            NotificationCenter.default.removeObserver(firstButtonObserver as Any)
        }
        var secondButtonObserver: NSObjectProtocol?
        secondButtonObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "SecondButtonPressed"), object: nil, queue: OperationQueue.main) {(notification) in
            completion(1)
            NotificationCenter.default.removeObserver(secondButtonObserver as Any)
        }
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }


    func showCenterTrophiesPopup(kasamID: String?) {
        var height = CGFloat(40)        //Badges Title height
        if kasamID == nil {
            //For Profile View page (lists all trophies)
            if SavedData.trophiesAchieved.count != 0 {height += CGFloat((SavedData.trophiesCount + SavedData.trophiesAchieved.count + 1) * 40)}
            else {height += CGFloat(80)}
        } else {
            //For specific Kasam
            if SavedData.trophiesAchieved[kasamID!] != nil {height += CGFloat((SavedData.trophiesAchieved[kasamID!]?.kasamTrophies.count ?? 0) + 2) * 40}
            else {height += CGFloat(80)}
        }
        var attributes = PopupAttributes.center()
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.9), height: .constant(value: height))
        
        let viewController = TrophiesAchieved()
        viewController.kasamID = kasamID
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }

    func showCenterOptionsPopup(kasamID: String?, title: String?, subtitle: String?, text: String?, type: String, button: String, completion:@escaping (Bool) -> ()) {
        var attributes = PopupAttributes.center()
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.8), height: .intrinsic)
        
        let vc = OptionsPopupController()
        vc.transfer = (kasamID, title, subtitle, text, type, button)
        var mainButtonPressedObserver: NSObjectProtocol?
        mainButtonPressedObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "MainButtonPressed"), object: nil, queue: OperationQueue.main) {(notification) in
            completion(true)
            NotificationCenter.default.removeObserver(mainButtonPressedObserver as Any)
        }
        var hiddenButtonPressedObserver: NSObjectProtocol?
        hiddenButtonPressedObserver = NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "HiddenButtonPressed"), object: nil, queue: OperationQueue.main) {(notification) in
            completion(false)
            NotificationCenter.default.removeObserver(hiddenButtonPressedObserver as Any)
        }
        SwiftEntryKit.display(entry: vc, using: attributes)
    }

    func showCenterGroupUserSearch(kasamID: String, completion:@escaping () -> ()) {
        var attributes = PopupAttributes.center()
        attributes.positionConstraints.size = .init(width: .ratio(value: 0.8), height: .constant(value: 400))
        let vc = GroupSearchController()
        vc.kasamID = kasamID
        SwiftEntryKit.display(entry: vc, using: attributes)
    }

    func showCenterSaveKasamPopup(level: Int, completion:@escaping (Int) -> ()) {
        var attributes = PopupAttributes.center()
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

    func showButtomAddKasamPopup(kasamID: String, state: String, duration: Int) {
        var attributes = PopupAttributes.bottom()
        if state != "edit" {attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: 500))}
        else {attributes.positionConstraints.size = .init(width: .fill, height: .constant(value: 300))}
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        let vC = AddKasamController()
        vC.kasamID = kasamID
        vC.repeatDuration = duration
        vC.state = state
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
