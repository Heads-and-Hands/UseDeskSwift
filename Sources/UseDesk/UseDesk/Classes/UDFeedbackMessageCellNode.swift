//
//  UDFeedbackMessageCellNode.swift

import UIKit
import AsyncDisplayKit

protocol UDFeedbackMessageCellNodeDelegate: AnyObject {
    func feedbackAction(indexPath: IndexPath, feedback: Bool)
}

class UDFeedbackMessageCellNode: UDMessageCellNode {
    private var isOutgoing = false
    private var textMessageNode = ASTextNode()
    private var dislikeButtonNode = ASButtonNode()
    private var likeButtonNode = ASButtonNode()
    
    var feedbackAction: Bool?
    weak var usedesk: UseDeskSDK?
    weak var delegate: UDFeedbackMessageCellNodeDelegate?
    
    override init() {
        super.init()
    }
    
    override func bindData(messagesView messagesView_: UDMessagesView?, message : UDMessage, avatarImage: UIImage?) {
        messagesView = messagesView_
        self.message = message
        self.isOutgoing = message.outgoing
        let feedbackMessageStyle = configurationStyle.feedbackMessageStyle
        feedbackAction = message.feedbackAction
        
        var attributedString = NSMutableAttributedString()
        let messageStyle = configurationStyle.messageStyle
        if message.attributedString != nil {
            attributedString = message.attributedString!
        } else {
            attributedString = NSMutableAttributedString(string: message.text)
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byWordWrapping
        attributedString.addAttributes([.font : messageStyle.font, .foregroundColor : message.outgoing ? messageStyle.textOutgoingColor : messageStyle.textIncomingColor, .paragraphStyle : paragraphStyle], range: NSRange(location: 0, length: attributedString.length))
        textMessageNode.attributedText = attributedString
        textMessageNode.style.alignSelf = .center
        addSubnode(textMessageNode)
        
        //dislike button
        if feedbackAction != nil {
            dislikeButtonNode.setBackgroundImage(feedbackMessageStyle.dislikeOnImage, for: .normal)
        } else {
            dislikeButtonNode.setBackgroundImage(feedbackMessageStyle.dislikeOffImage, for: .normal)
        }
        dislikeButtonNode.addTarget(self, action: #selector(self.dislikeButton_pressed(_:)), forControlEvents: .touchUpInside)
        dislikeButtonNode.alpha = 0
        dislikeButtonNode.isUserInteractionEnabled = true
        dislikeButtonNode.style.width = ASDimensionMakeWithPoints(feedbackMessageStyle.buttonSize.width)
        dislikeButtonNode.style.height = ASDimensionMakeWithPoints(feedbackMessageStyle.buttonSize.height)
        addSubnode(dislikeButtonNode)
        
        //like button
        if feedbackAction != nil {
            likeButtonNode.setBackgroundImage(feedbackMessageStyle.likeOnImage, for: .normal)
        } else {
            likeButtonNode.setBackgroundImage(feedbackMessageStyle.likeOffImage, for: .normal)
        }
        likeButtonNode.addTarget(self, action: #selector(self.likeButton_pressed(_:)), forControlEvents: .touchUpInside)
        likeButtonNode.alpha = 0
        likeButtonNode.isUserInteractionEnabled = true
        likeButtonNode.style.width = ASDimensionMakeWithPoints(feedbackMessageStyle.buttonSize.width)
        likeButtonNode.style.height = ASDimensionMakeWithPoints(feedbackMessageStyle.buttonSize.height)
        addSubnode(likeButtonNode)
        
        // visible buttons
        if feedbackAction != nil {
            likeButtonNode.alpha = feedbackAction! ? 1 : 0
            dislikeButtonNode.alpha = feedbackAction! ? 0 : 1
        } else {
            likeButtonNode.alpha = 1
            dislikeButtonNode.alpha = 1
        }
        super.bindData(messagesView: messagesView, message: message, avatarImage: avatarImage)
    }
    
    override public func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let messageStyle = configurationStyle.messageStyle
        let feedbackMessageStyle = configurationStyle.feedbackMessageStyle
        let sizeMessagesManager = UDSizeMessagesManager(messagesView: messagesView, message: message, indexPath: indexPath, configurationStyle: configurationStyle)
        
        let hButtonsStack = ASStackLayoutSpec()
        hButtonsStack.direction = .horizontal
        hButtonsStack.spacing = feedbackMessageStyle.buttonsSpacing
        hButtonsStack.alignItems = .center
        if feedbackAction != nil {
            if feedbackAction! {
                hButtonsStack.children?.append(likeButtonNode)
            } else {
                hButtonsStack.children?.append(dislikeButtonNode)
            }
        } else {
            hButtonsStack.children?.append(dislikeButtonNode)
            hButtonsStack.children?.append(likeButtonNode)
        }
        let hButtonsInsetStack = ASInsetLayoutSpec(insets: UIEdgeInsets(top: feedbackMessageStyle.buttonsMarginTop, left: 0, bottom: 0, right: 0), child: hButtonsStack)
        
        textMessageNode.style.maxWidth = ASDimensionMakeWithPoints(sizeMessagesManager.maxWidthBubbleMessage - feedbackMessageStyle.textMargin.left - feedbackMessageStyle.textMargin.right)
        let textMessageInsetStack = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: feedbackMessageStyle.textMargin.left, bottom: 0, right: feedbackMessageStyle.textMargin.right), child: textMessageNode)
        let vButtonsAndTextStack = ASStackLayoutSpec(direction: .vertical, spacing: feedbackMessageStyle.textMargin.top, justifyContent: .center, alignItems: ASStackLayoutAlignItems.center, children: [hButtonsInsetStack, textMessageInsetStack])
        
        let vMessageStack = ASStackLayoutSpec()
        vMessageStack.direction = .vertical
        vMessageStack.style.flexShrink = 1.0
        vMessageStack.style.flexGrow = 0
        vMessageStack.style.maxWidth = ASDimensionMakeWithPoints(sizeMessagesManager.maxWidthBubbleMessage)
        vMessageStack.spacing = 0
        vMessageStack.alignItems = .end
        vMessageStack.children?.append(vButtonsAndTextStack)
        vMessageStack.style.maxWidth = sizeMessagesManager.maxWidthBubbleMessageDimension
        
        timeNode.style.alignSelf = .end
        let timeInsetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 0, left: 0, bottom: messageStyle.timeMargin.bottom, right: message.outgoing ? 0 : messageStyle.timeMargin.right), child: timeNode)
        
        sendedImageNode.style.alignSelf = .end
        sendedImageNode.style.maxSize = messageStyle.sendedStatusSize
        
        var timeEndSendedLayoutElements: [ASLayoutElement] = [timeInsetSpec]
        if message.outgoing {
            timeEndSendedLayoutElements.append(sendedImageNode)
        }
        let horizon = ASStackLayoutSpec(direction: .horizontal, spacing: 0, justifyContent: .end, alignItems: .end, children: timeEndSendedLayoutElements)
        vMessageStack.children?.append(horizon)
        
        contentMessageInsetSpec = ASInsetLayoutSpec(insets: UIEdgeInsets.zero, child: vMessageStack)
        let messageLayoutSpec = super.layoutSpecThatFits(constrainedSize)
        return messageLayoutSpec
    }
    
    @objc func dislikeButton_pressed(_ sender: Any?) {
        feedbackAction = false
        likeButtonNode.isUserInteractionEnabled = false
        var frame = dislikeButtonNode.frame
        frame.origin.x += ((configurationStyle.feedbackMessageStyle.buttonSize.width / 2) + (configurationStyle.feedbackMessageStyle.buttonsSpacing / 2))
        dislikeButtonNode.setBackgroundImage(configurationStyle.feedbackMessageStyle.dislikeOnImage, for: .normal)
        UIView.animate(withDuration: 0.4) {
            self.dislikeButtonNode.frame = frame
            self.likeButtonNode.alpha = 0
        } completion: { (_) in
            let indexPathCell = self.indexPath
            if indexPathCell != nil {
                self.delegate?.feedbackAction(indexPath: indexPathCell!, feedback: false)
            }
            self.usedesk?.sendMessageFeedBack(false, message_id: self.message.id)
        }
    }
    
    @objc func likeButton_pressed(_ sender: Any?) {
        feedbackAction = true
        likeButtonNode.isUserInteractionEnabled = false
        var frame = likeButtonNode.frame
        frame.origin.x -= ((configurationStyle.feedbackMessageStyle.buttonSize.width / 2) + (configurationStyle.feedbackMessageStyle.buttonsSpacing / 2))
        likeButtonNode.setBackgroundImage(configurationStyle.feedbackMessageStyle.likeOnImage, for: .normal)
        UIView.animate(withDuration: 0.4) {
            self.likeButtonNode.frame = frame
            self.dislikeButtonNode.alpha = 0
        } completion: { (_) in
            if self.indexPath != nil {
                self.delegate?.feedbackAction(indexPath: self.indexPath!, feedback: true)
            }
            self.usedesk?.sendMessageFeedBack(true, message_id: self.message.id)
        }
    }
}
