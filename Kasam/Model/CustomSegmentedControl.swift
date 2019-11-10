//
//  CustomSegmentedControl.swift
//  Kasam
//
//  Created by Vance Basilio on 2019-11-09.
//  Copyright © 2019 Vance Basilio. All rights reserved.
//

import UIKit

@IBDesignable

class CustomSegmentedControl: UIControl {
    var buttons = [UIButton]()
    var selector: UIView!
    var selectedSegmentIndex = 0
    
    @IBInspectable
    var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable
    var borderColor: UIColor = UIColor.white {
        didSet {
            layer.borderColor = borderColor.withAlphaComponent(0.6).cgColor
        }
    }
    
    @IBInspectable
    var commaSeparatedButtonTitltes: String = "" {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var textColor: UIColor = .lightGray {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var selectorColor: UIColor = .darkGray {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable
    var selectorTextColor: UIColor = .white {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        buttons.removeAll()
        subviews.forEach { $0.removeFromSuperview()}
        
        let buttonTitles = commaSeparatedButtonTitltes.components(separatedBy: ",")
        
        for buttonTitle in buttonTitles {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitle, for: .normal)
            button.titleLabel!.font = UIFont.boldSystemFont(ofSize: 13)
            button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
            buttons.append(button)
        }
        
        buttons[0].setTitleColor(selectorTextColor, for: .normal)
        
        let selectorWidth = frame.width / CGFloat(buttonTitles.count)
        let background = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        let border = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        
        background.layer.cornerRadius = frame.height / 2
        border.layer.cornerRadius = frame.height / 2
        background.backgroundColor = borderColor.withAlphaComponent(0.8)
        
        border.layer.backgroundColor = UIColor.clear.cgColor
        border.layer.borderWidth = borderWidth
        border.layer.borderColor = borderColor.withAlphaComponent(0.6).cgColor
        
        selector = UIView(frame: CGRect(x: 0, y: 0, width: selectorWidth, height: frame.height))
        selector.layer.cornerRadius = frame.height / 2
        selector.backgroundColor = selectorColor
        
        addSubview(background)
        addSubview(selector)
        addSubview(border)
        
        let sv = UIStackView(arrangedSubviews: buttons)
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
        addSubview(sv)
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        sv.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        sv.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        sv.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    override func draw(_ rect: CGRect) {
        layer.cornerRadius = frame.height / 2
        updateView()
    }
    
    @objc func buttonTapped(button: UIButton) {
        for (buttonIndex, btn) in buttons.enumerated() {
            btn.setTitleColor(textColor, for: .normal)
            
            if btn == button {
                selectedSegmentIndex = buttonIndex
                let selectorStartPosition = frame.width/CGFloat(buttons.count) * CGFloat(buttonIndex)
                UIView.animate(withDuration: 0.3, animations:  {
                    self.selector.frame.origin.x = selectorStartPosition
                })
                btn.setTitleColor(selectorTextColor, for: .normal)
            } else {
                btn.setTitleColor(UIColor.white, for: .normal)
            }
        }
        sendActions(for: .valueChanged)
    }
    
    func changeScroll(index: Int) {
        selectedSegmentIndex = index
        let selectorStartPosition = frame.width/CGFloat(buttons.count) * CGFloat(index)
        UIView.animate(withDuration: 0.3, animations:  {
            self.selector.frame.origin.x = selectorStartPosition
        })
    }
    
}
