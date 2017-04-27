//
//  TestJSObject.h
//  JSMethodTest
//
//  Created by Madis on 2017/4/26.
//  Copyright © 2017年 xl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

//遵守JSExport协议
@protocol TestJSObjectProtocol <JSExport>

- (void)testNOParmaters;
- (void)testParmaters:(NSString *)parmater1 Parmater2:(NSString *)parmater2;

@end

@interface TestJSObject : NSObject<TestJSObjectProtocol>

@end
