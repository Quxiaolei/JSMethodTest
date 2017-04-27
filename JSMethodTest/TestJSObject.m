//
//  TestJSObject.m
//  JSMethodTest
//
//  Created by Madis on 2017/4/26.
//  Copyright © 2017年 xl. All rights reserved.
//

#import "TestJSObject.h"

@implementation TestJSObject

- (void)testNOParmaters{
    NSLog(@"there is no parmaters");
}

- (void)testParmaters:(NSString *)parmater1 Parmater2:(NSString *)parmater2{
    NSLog(@"the parmater1 is %@,paramter2 is %@",parmater1,parmater2);
}

@end
