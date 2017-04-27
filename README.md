#### `UIWebView`的JS交互方式:

相关操作一般在`webViewDidFinishLoad`delegate方法中

###### 使用`stringByEvaluatingJavaScriptFromString`方法

此方法是同步方法,使用它执行JS方法时,如果JS方法比较耗的时候,会造成界面卡顿.使用JS弹出AlertView时会阻塞界面等待用户响应,就会造成死锁.建议延迟执行JS的`alert`方法.

常见使用:

```objective-c
- (void)webViewDidFinishLoad:(UIWebView *)webView {
  NSLog(@"webView加载完成:\n%@",webView.request.URL.absoluteString);
  //获取当前页面的title
  NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
  //获取当前页面的url
  NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.location.href"];
  //获取当前页面高度
  NSString *height = [webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"];

  //设置禁止选中
  [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitUserSelect='none';"];
  [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.style.webkitTouchCallout='none';"];
}
```

###### 使用`JavaScriptCore`类库方法进行OC与JS之间交互

`JSContext`:给JavaScript提供运行的上下文环境,通过`evaluateScript`方法就可以执行JS代码

`JSValue`:JavaScript和Objective-C数据和方法的桥梁,封装了JS与ObjC中的对应的类型,以及调用JS的API等

`JSManagedValue`:管理数据和方法的类

`JSVirtualMachine`:处理线程相关,使用较少

`JSExport`:这是一个协议,我们可以在类中声明属性,类方法,实例方法等,继承的协议会自动提供给任何的JS代码.如果采用协议的方法交互,必须遵守自定义的协议

OC调用JS:

1. `evaluateScript:`方法和`evaluateScript:withSourceURL:`方法

2. 使用`JSValue`的`callWithArguments:`方法

3. 使用`stringByEvaluatingJavaScriptFromString:`方法

简单使用:

```objective-c
//获取webView的jsContext方法
JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//检测JS错误,抛出JavaScript运行异常
context.exceptionHandler = ^(JSContext *con, JSValue *exceptionValue) {
    NSLog(@"exceptionValue:%@", exceptionValue);
    con.exception = exceptionValue;
};
//加法运算
[context evaluateScript:@"function add(a, b) { return a + b; }"];
JSValue *addValue = context[@"add"];
NSLog(@"Func: %@", addValue);
//OC传递参数给JS
JSValue *sumValue = [addValue callWithArguments:@[@7, @21]];
NSLog(@"Sum: %d",[sumValue toInt32]);

//使用block直接调用对应的context
context[@"share"] = ^() {
    NSLog(@"+++++++Begin Log+++++++");
    //获取参数列表
    NSArray *args = [JSContext currentArguments];
    //获取当前调用该方法的对象
    JSValue *this = [JSContext currentThis];
    NSLog(@"this: %@",this);

    NSMutableArray *mutableArray = [NSMutableArray new];
    for (JSValue *jsVal in args) {
        NSLog(@"%@", jsVal.toString);
        [mutableArray addObject:jsVal.toString ];
    }
    if(mutableArray.count >=2){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:mutableArray[0]
                                        message:mutableArray[1]
                                       delegate:nil
                              cancelButtonTitle:@"好的"
                              otherButtonTitles:nil] show];
        });
    }
    NSLog(@"-------End Log-------");
};
[context evaluateScript:@"share('参数1','参数2')"];
```

扩展使用:自定义对象,内部实现遵守`JSExport`协议的方法

```objective-c
//TestJSObject.h

//遵守JSExport协议
@protocol TestJSObjectProtocol <JSExport>

- (void)testNOParmaters;
- (void)testParmaters:(NSString *)parmater1 Parmater2:(NSString *)parmater2;

@end
@interface TestJSObject : NSObject<TestJSObjectProtocol>

@property (nonatomic, weak) JSContext *jsContext;
@property (nonatomic, weak) UIWebView *webView;
@end


//TestJSObject.m

// JS调用了callSystemCamera
- (void)callSystemCamera {
 NSLog(@"JS调用了OC的方法，调起系统相册");

 // JS调用后OC后，又通过OC调用JS，但是这个是没有传参数的
 JSValue *jsFunc = self.jsContext[@"jsFunc"];
 [jsFunc callWithArguments:nil];
}

- (void)jsCallObjcAndObjcCallJsWithDict:(NSDictionary *)params {
 NSLog(@"jsCallObjcAndObjcCallJsWithDict was called, params is %@", params);

 // 调用JS的方法
 JSValue *jsParamFunc = self.jsContext[@"jsParamFunc"];
 [jsParamFunc callWithArguments:@[@{@"age": @10, @"name": @"lili", @"height": @158}]];
}
```

```objective-c
//测试自定义对象
TestJSObject *testObj = [TestJSObject new];
testObj.jsContext = context;
testObj.webView = self.webView;
//上文获取的context
//必须和JS代码中的对象对应
context[@"testobject"] = testObj;

[context evaluateScript:@"testobject.testNOParmaters()"];
[context evaluateScript:@"testobject.testParmatersParmater2('参数A','参数B')"];
```

对应的html代码:
```html
<div style="margin-top: 100px">
<h1>Test how to use objective-c call js</h1>
<input type="button" value="Call ObjC system camera" onclick="testobject.callSystemCamera()">
<input type="button" value="Call ObjC system alert" onclick="testobject.showAlertMsg('js title', 'js message')">
</div>

<div>
<input type="button" value="Call ObjC func with JSON " onclick="testobject.callWithDict({'name': 'testname', 'age': 10, 'height': 170})">
<input type="button" value="Call ObjC func with JSON and ObjC call js func to pass args." onclick="testobject.jsCallObjcAndObjcCallJsWithDict({'name': 'testname', 'age': 10, 'height': 170})">
</div>

<div>
<span id="jsParamFuncSpan" style="color: red; font-size: 50px;"></span>
</div>
```

```javascript
var jsFunc = function() {
  alert('Objective-C call js to show alert');
}

var jsParamFunc = function(argument) {
  document.getElementById('jsParamFuncSpan').innerHTML
  = argument['name'];
}
```

###### 伪JS交互方式

在`webView:shouldStartLoadWithRequest:navigationType:`(`UIWebView`),

`webView:decidePolicyForNavigationAction:decisionHandler`(`WKWebView`)方法中拦截超链的url,通过处理url做出相应操作

```objective-c
// 在发送请求之前，决定是否跳转
//- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"在发送请求之前，决定是否跳转");
    NSURL *abcURL = navigationAction.request.URL;
    NSString *abcUrlStr = abcURL.absoluteString;
    NSLog(@"当前的获取URL == %@", abcUrlStr);
    if ([abcURL.scheme isEqualToString:@"firstclick"]) {
        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithCapacity:0];
        NSURLComponents *URLComponents = [NSURLComponents componentsWithString:abcUrlStr];
        NSArray *URLqueryItems = URLComponents.queryItems;
        if (URLComponents && URLqueryItems.count >0) {
            for (NSURLQueryItem *item in URLqueryItems) {
                [mutableDict setObject:item.value forKey:item.name];
            }
        }
        [[[UIAlertView alloc] initWithTitle:mutableDict[@"title"]
                                    message:mutableDict[@"content"]
                                   delegate:nil
                          cancelButtonTitle:@"好的"
                          otherButtonTitles:nil] show];
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *methodString = [abcURL.host stringByAppendingString:@":"];
            SEL selector = NSSelectorFromString(methodString);
            NSLog(@"当前获取method == %@ paramsDict == %@", methodString,mutableDict);
            IMP imp = [self methodForSelector:selector];
            if ([self respondsToSelector:selector]) {
                void (*func)(id, SEL,id) = (void *)imp;
                dispatch_async(dispatch_get_main_queue(), ^{
                    func(self, selector,mutableDict);
                });
            }

        });
        decisionHandler(WKNavigationActionPolicyCancel);
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)shareClick:(NSString *)params{
    NSLog(@"shareClick params:%@",params);
}

```

**注:**

1.`UIWebView`中`JSContext`创建时机,当网页渲染时遇到`<script`标签或者调用`[webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"]`都会去创建`JSContext`环境,两种方式获取的环境变量是同一个.

2.JS调用原生的方法最好在`viewDidLoad`中webView被创建时就添加,在`webViewDidFinishLoad:`方法中再添加一次,避免网页加载完成前进行JS操作引起的bug

3.一个webView中重复加载多个网页时会存在内存泄露:

webView的层级结构为:`webView`-> `webScrollView`-> `UIWebBrowserView`,最终，让用户能看到html内容的,就是`UIWebBrowserView`.所以,界面的触摸事件都会加在`UIWebBrowserView`上.

反复调用webView的`load`方法时,`_UITextSelectionForceGesture`手势的引用计数就会不断加1,原因是触摸事件和观察者之间存在循环引用.([Apple埋的坑：UIWebView](http://www.qingpingshan.com/rjbc/ios/210952.html))

#### `WKWebView`

含有`allowsBackForwardNavigationGestures`右滑返回手势,`estimatedProgress`预估进度,`allowsInlineMediaPlayback`是否允许内嵌视频播放等新属性

`WKNavigationDelegate`:类比`UIWebView`的加载代理方法

`WKUIDelegate`:JS调用原生的alert,confirm等弹窗方法时需要设置此代理

`WKScriptMessageHandler`:和JS交互相关

在`UIWebView`末尾增加一个View,根据View高度改变ScrollView的`contentSize`属性.

在`WKWebView`末尾增加一个View,只能在webView加载完成后,给webView页面底部增加一对空白的`div`,再将空白View加在空白`div`位置.参见:[WKWebView使用及注意点(keng)](http://www.jianshu.com/p/9513d101e582)

#### `WKWebView`的JS交互方式:

使用`WKWebView`时,需要手动导入`#import <WebKit/WebKit.h>`

使用`WKScriptMessageHandler`时必须实现`WKScriptMessageHandler`协议

使用`addScriptMessageHandler:name:`方法进行JS交互,第一个参数是userContentController的代理对象,第二个参数是JS里发送postMessage的对象.在JS方法中使用`window.webkit.messageHandlers.<name>.postMessage(<messageBody>)`传递数据

```objective-c
- (void)viewDidLoad {
    [super viewDidLoad];

    WKWebViewConfiguration *webViewConfig = [WKWebViewConfiguration new];
    //window.webkit.messageHandlers.webViewApp.postMessage
    //调用时name一定要保持一致
    [webViewConfig.userContentController addScriptMessageHandler:self name:@"webViewApp"];
}

#pragma mark - WKScriptMessageHandler
//接收网页消息的回调方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"message name:%@,body:%@",message.name,message.body);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // 控制器 强引用了WKWebView,WKWebView copy(强引用了）configuration， configuration copy （强引用了）userContentController
    // userContentController 强引用了 self （控制器）
    //不释放时会导致交互对象内存常驻
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"webViewApp"];
}

```
在APP中给JS发送消息
```objective-c
NSString *str = @"{'method' : 'showAlert','message' : 'wkWebView',}";
//window.webkit.messageHandlers.<name>.postMessage(<messageBody>)
[self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"window.webkit.messageHandlers.webViewApp.postMessage(%@)",str] completionHandler:^(id _Nullable data, NSError * _Nullable error) {
    NSLog(@"可以通过手动调用js方法发送消息");
}];
```
在H5中调用JS给APP发送消息
```javascript
var message = {
  'method' : 'showAlert',
  'message' : 'wkWebView',
};
// 调用JS方法给APP发送消息
window.webkit.messageHandlers.webViewApp.postMessage(message);
```
#### Cordova基础
[iOS下JS与OC互相调用（八）--Cordova详解+实战](http://www.jianshu.com/p/e74bc7abac8d)

参考资料:

[iOS7新JavaScriptCore框架入门介绍](http://blog.iderzheng.com/introduction-to-ios7-javascriptcore-framework/)

[JavaScriptCore框架在iOS7中的对象交互和管理](http://blog.iderzheng.com/ios7-objects-management-in-javascriptcore-framework/)

[iOS下JS与原生OC互相调用(总结)](http://www.jianshu.com/p/d19689e0ed83)

[JS和UIWebview通过JavaScriptCore无法执行iOS本地方法解决方案](https://galileioo.github.io/posts/UIWebview-JS.html):在网页加载完成前,先加载JS获取`JSContext`对象执行相关操作

[网易新闻客户端iOS版本中新闻详情页（UIWebView）技术实现的分析](http://386502324.blog.163.com/blog/static/11346937720154293438399/)

[WKWebView使用及注意点(keng)](http://www.jianshu.com/p/9513d101e582)
