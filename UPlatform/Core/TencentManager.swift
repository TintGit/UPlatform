//
//  TencentManager.swift
//  UGuide
//
//  Created by yanming on 2018/6/13.
//  Copyright © 2018年 wakeup. All rights reserved.
//

import UIKit

public class TencentManager: NSObject, QQApiInterfaceDelegate, TencentSessionDelegate{
    public func tencentDidLogin() {
        
    }
    
    public func tencentDidNotLogin(_ cancelled: Bool) {
        
    }
    
    public func tencentDidNotNetWork() {
        
    }
    
    public func onReq(_ req: QQBaseReq!) {
        
    }
    
    
    public func onResp(_ resp: QQBaseResp!) {
        print(resp.result,resp.errorDescription)
        let message = (resp.errorDescription == nil ? "" : resp.errorDescription) ?? ""
        let result = UGuideResult(resp.result == "0" ? true : false, code: Int(resp.result) ?? -1, message: message)
            self.completion?(result)
    }
    public func isOnlineResponse(_ response: [AnyHashable : Any]!) {
        
    }
    
    static let shared = TencentManager()
    var completion: ((UGuideResult)->())?
}
