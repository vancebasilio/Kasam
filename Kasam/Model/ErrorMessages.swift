//
//  ErrorMessages.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-26.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import Foundation
import SwiftEntryKit

    //BOTTOM FLOAT CELL---------------------------------------------------------------------------------------------------
    func floatCellSelected(title: String, description: String) {
        var attributes: EKAttributes
        attributes = .topFloat
        attributes.displayMode = .light
        attributes.hapticFeedbackType = .success
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.colorFour), EKColor(UIColor.colorFive)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.entryInteraction = .delayExit(by: 3)
        attributes.scroll = .enabled(
            swipeable: true,
            pullbackAnimation: .jolt
        )
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

    //UNFOLLOW BUTTON CONFIRMATION-------------------------------------------------------------------------------------------------

    func showUnfollowConfirmation(title: String, description: String, completion:@escaping (Bool) -> ()) {
        var attributes: EKAttributes
        attributes = EKAttributes.centerFloat
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity
        attributes.entryBackground = .gradient(gradient: .init(colors: [EKColor(UIColor.colorFour), EKColor(UIColor.colorFour)], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
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
        
        let image = UIImage.init(icon: .fontAwesomeSolid(.heartbeat), size: CGSize(width: 35, height: 35), textColor: .white)
        let title = title
        let description = description
        var themeImage: EKPopUpMessage.ThemeImage?
        themeImage = EKPopUpMessage.ThemeImage(image: EKProperty.ImageContent(image: image, displayMode: .light, size: CGSize(width: 60, height: 60), tint: .white, contentMode: .scaleAspectFit))
        let finalTitle = EKProperty.LabelContent(text: title, style: .init(font: UIFont.systemFont(ofSize: 26, weight: .bold), color: .white, alignment: .center, displayMode: .light))
        let finalDescription = EKProperty.LabelContent(text: description, style: .init(font: UIFont.systemFont(ofSize: 18, weight: .semibold), color: .white, alignment: .center, displayMode: .light))
        let button = EKProperty.ButtonContent(label: .init(text: "Unfollow", style: .init(font: UIFont.systemFont(ofSize: 16, weight: .semibold), color: EKColor(UIColor.colorFive),displayMode: .light)), backgroundColor: .white, highlightedBackgroundColor: EKColor(UIColor.colorFive).with(alpha: 0.05), displayMode: .light)
        let message = EKPopUpMessage(themeImage: themeImage, title: finalTitle, description: finalDescription, button: button) {
            completion(true)
            SwiftEntryKit.dismiss()
        }
        let contentView = EKPopUpMessageView(with: message)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    //USER OPTIONS-------------------------------------------------------------------------------------------------
    func showUserOptions() {
        var attributes: EKAttributes
        attributes = .bottomFloat
        attributes.displayMode = .light
        attributes.displayDuration = .infinity
        attributes.screenBackground = .color(color: EKColor(UIColor(white: 100.0/255.0, alpha: 0.3)))
        attributes.entryBackground = .color(color: .white)
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .dismiss
        attributes.entranceAnimation = .init(translate: .init(duration: 0.5, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.35))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 6))
        attributes.roundCorners = .all(radius: 20)
        attributes.positionConstraints.size = .init(width: .fill, height: .ratio(value: 0.5))
        attributes.positionConstraints.verticalOffset = -100
        attributes.positionConstraints.safeArea = .overridden
        attributes.statusBar = .dark
        
        let viewController = UserOptionsController()
        SwiftEntryKit.display(entry: viewController, using: attributes)
    }