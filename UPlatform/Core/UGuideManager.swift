//
//  UGuideManager.swift
//  UGuide
//
//  Created by yanming on 2018/6/12.
//  Copyright © 2018年 wakeup. All rights reserved.
//
//$(SWIFT_MODULE_NAME)-Swift.h
import UIKit


public class UGuideManager: NSObject {
    public static let defaultManager = UGuideManager()
    public typealias UGuideRequestCompletionHandler = (UGuideResult)->()
    fileprivate var shareCompletionHandler : UGuideRequestCompletionHandler?
    fileprivate var authCompletionHandler : UGuideRequestCompletionHandler?
    private var qq_appKey : String?
    private var sina_appKey : String?
    /**
     *  设置平台的appkey
     *
     *  @param platformType 平台类型 @see UGuidePlatformType
     *  @param appKey       第三方平台的appKey（QQ平台为appID）
     *  @param appSecret    第三方平台的appSecret（QQ平台为appKey）
     *  @param redirectURL  redirectURL
     */
    public func setPlaform(_ plaformType: UGuidePlatformType, appKey: String, appSecret: String, redirectURI: String? = nil){
        switch plaformType {
        case .wechatSession, .wechatTimeline:
            WXApi.registerApp(appKey)
            break
        case .qq:
            let tencent = TencentOAuth(appId: appKey, andDelegate: TencentManager.shared)
            tencent?.redirectURI = redirectURI ?? "www.qq.com"
            self.qq_appKey = appKey
            break
        case .sina:
            WeiboSDK.registerApp(appKey)
            break
        }
    }
    
}
//MARK: - 回调
extension UGuideManager {
    /**
     *  获得从sso或者web端回调到本app的回调
     *
     *  @param url 第三方sdk的打开本app的回调的url
     *
     *  @return 是否处理  YES代表处理成功，NO代表不处理
     */
    public func handleOpenURL(_ url: URL) -> Bool{
        guard let scheme = url.scheme else{return false}
        if scheme.contains("wuAlipay"){
            return true
        }
        if scheme.contains("tencent\(self.qq_appKey ?? "")"){
            return QQApiInterface.handleOpen(url, delegate: TencentManager.shared)
        }
        if scheme.contains("wb\(self.sina_appKey ?? "")") {
            return WeiboSDK.handleOpen(url, delegate: self)
        }
        return WXApi.handleOpen(url, delegate: self)
    }
}
//MARK: - 平台是否安装
extension UGuideManager {
    /**
     *  平台是否安装
     *
     *  @param platformType 平台类型 @see UMSocialPlatformType
     *
     *  @return YES 代表安装，NO 代表未安装
     *  在判断QQ空间的App的时候，QQApi判断会出问题
     */
    public func isInstall(plaformType: UGuidePlatformType) -> Bool{
        switch plaformType {
        case .wechatSession, .wechatTimeline:
            return WXApi.isWXAppInstalled()
        case .qq:
            return QQApiInterface.isQQInstalled()
        case .sina:
            return WeiboSDK.isWeiboAppInstalled()
        }
    }
}
//MARK: - 授权平台
extension UGuideManager {
    /**
     *  授权平台 (此方法仅获取授权token)
     *
     *  @param platformType  平台类型 @see UGuidePlatformType
     *  @param currentViewController 用于弹出类似邮件分享、短信分享等这样的系统页面
     *  @discuss currentViewController 只对sms,email等平台需要传入viewcontroller的平台，其他不需要的平台可以传入nil
     *  @param completion   回调
     */
    public func authWithPlatform(_ plaformType: UGuidePlatformType, currentViewController: UIViewController? = nil, completion: UGuideRequestCompletionHandler?){
        switch plaformType {
        case .wechatSession, .wechatTimeline:
            wechatAuth(currentViewController)
            self.authCompletionHandler = completion
            break
        case .qq:
           let result = UGuideResult(false, code: -1, message: "暂不支持qq授权")
           completion?(result)
            break
        case .sina:
            let result = UGuideResult(false, code: -1, message: "暂不支持微博授权")
            completion?(result)
            break
        }
        
    }
    func wechatAuth(_ currentViewController: UIViewController? = nil) {
        let req = SendAuthReq()
        req.scope = "snsapi_message,snsapi_userinfo,snsapi_friend,snsapi_contact"
        req.state = "234"
        let b = WXApi.sendAuthReq(req, viewController: currentViewController, delegate: self)
        if !b {
            let result = UGuideResult(false, code: -1, message: "微信应答失败")
            self.authCompletionHandler?(result)
        }
    }
}
//MARK: - 分享
extension UGuideManager {
    /**
     *  设置分享平台
     *
     *  @param platformType  平台类型 @see UGuidePlatformType
     *  @param messageObject  分享的content @see UGuideMessageObject
     *  @param currentViewController 用于弹出类似邮件分享、短信分享等这样的系统页面
     *  @param completion   回调
     *  @discuss currentViewController 只正对sms,email等平台需要传入viewcontroller的平台，其他不需要的平台可以传入nil
     */
    func shareToPlatform(_ plaformType: UGuidePlatformType, messageObject: UGuideMessageObject, currentViewController: UIViewController? = nil, completion: UGuideRequestCompletionHandler?){
        switch plaformType {
        case .wechatSession, .wechatTimeline:
            wechatShare(messageObject, type: plaformType)
            self.shareCompletionHandler = completion
            break
        case .qq:
            tencentShare(messageObject)
            TencentManager.shared.completion = completion
            break
        case .sina:
            sinaShare(messageObject)
            self.shareCompletionHandler = completion
            break
        }
        
    }
    private func wechatShare(_ messageObject: UGuideMessageObject, type: UGuidePlatformType){
        let wxObj = WXWebpageObject()
        wxObj.webpageUrl = messageObject.webpageUrl
        let wxMes = WXMediaMessage()
        wxMes.title = messageObject.title
        wxMes.description = messageObject.desc
        wxMes.mediaObject = wxObj
        
        let req = SendMessageToWXReq()
        req.bText = false
        req.message = wxMes
        req.scene = Int32(type.rawValue - 1)
        let b = WXApi.send(req)
        if !b {
            let res = UGuideResult(false, code: -1, message: "微信应答失败")
            self.shareCompletionHandler?(res)
        }
    }
    private func tencentShare(_ messageObject: UGuideMessageObject){
        guard let urlcode = messageObject.webpageUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),let url = URL.init(string: urlcode) else{return}
        let obj = QQApiNewsObject(url: url, title: messageObject.title, description: messageObject.desc, previewImageData: Data(), targetContentType: QQApiURLTargetTypeNews)
        obj?.shareDestType = ShareDestTypeQQ
        let req = SendMessageToQQReq(content: obj)
        let code = QQApiInterface.send(req)
        if code.rawValue != 0{
            let res = UGuideResult(false, code: Int(code.rawValue), message: "QQ应答失败")
            self.shareCompletionHandler?(res)
        }
    }
    private func sinaShare(_ messageObject: UGuideMessageObject){
        let authReq = WBAuthorizeRequest()
        authReq.redirectURI = "https://www.sina.com"
        authReq.scope = "all"
        
        let webPage = WBWebpageObject()
        webPage.objectID = "identifier1"
        webPage.title = messageObject.title
        webPage.description = messageObject.desc
        webPage.webpageUrl = messageObject.webpageUrl
        
        let message = WBMessageObject()
        message.mediaObject = webPage
        
        let request = WBSendMessageToWeiboRequest.request(withMessage: message, authInfo: authReq, access_token: nil) as! WBSendMessageToWeiboRequest
        request.userInfo = ["ShareMessageFrom": "SendMessageToWeiboViewController",
                            "Other_Info_1": "123",
                            "Other_Info_2": ["obj1", "obj2"],
                            "Other_Info_3": ["key1": "obj1", "key2": "obj2"]]
        let b = WeiboSDK.send(request)
        if !b {
            let res = UGuideResult(false, code: -1, message: "微博应答失败")
            self.shareCompletionHandler?(res)
        }
    }
}
//MARK: - 微信回调
extension UGuideManager: WXApiDelegate{
    public func onResp(_ resp: BaseResp!) {
        let message = (resp.errStr == nil ? "" : resp.errStr) ?? ""
        let success = resp.errCode == 0 ? true : false
        let code = Int(resp.errCode)
        if resp.isKind(of: SendAuthResp.self) {//登录回调
            let authResp = resp as! SendAuthResp
            let result = UGuideResult(success, code: code, message: message)
            result.authCode = authResp.code
            self.authCompletionHandler?(result)
        }
        if resp.isKind(of: SendMessageToWXResp.self) {//分享回调
            let _ = resp as! SendMessageToWXResp
            let result = UGuideResult(success, code: Int(resp.errCode), message: message)
            self.shareCompletionHandler?(result)
        }
        if resp.isKind(of: PayResp.self) {//支付回调
            
        }
    }
}
//MARK: - 微博回调
extension UGuideManager: WeiboSDKDelegate{
    public func didReceiveWeiboRequest(_ request: WBBaseRequest!) {
        
    }
    public func didReceiveWeiboResponse(_ response: WBBaseResponse!) {
        if response.isKind(of: WBSendMessageToWeiboResponse.classForCoder()) {
            let request = UGuideResult(response.statusCode == .success ? true : false, code: response.statusCode.rawValue, message: "")
            self.shareCompletionHandler?(request)             
        }
    }
    
}

