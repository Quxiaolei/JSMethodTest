//
//  ViewController.h
//  JSMethodTest
//
//  Created by Madis on 2017/4/24.
//  Copyright © 2017年 xl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController


@end

//网易新闻富文本展示策略
//采用json数据+本地网页模板展示
//http://386502324.blog.163.com/blog/static/11346937720154293438399/
//https://github.com/JokerXu/webViewDemo



//UIWebView的JS调用方法:
//1.通过拦截request请求地址的方式实现
//2.通过获取JavaScriptCore的jsContext注册objc对象或者使用JSExport协议导出Native对象
//WKWebView 不支持JavaScriptCore的方式但提供message handler的方式为JavaScript 与Objective-C 通信.
