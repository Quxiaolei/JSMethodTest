//
//  ViewController.m
//  JSMethodTest
//
//  Created by Madis on 2017/4/24.
//  Copyright © 2017年 xl. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import <JavaScriptCore/JavaScriptCore.h>
//自定义的测试对象,实现JSExport
#import "TestJSObject.h"

#define kScreenWidth [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight [[UIScreen mainScreen] bounds].size.height

@interface ViewController ()
<
WKNavigationDelegate,
WKUIDelegate,
WKScriptMessageHandler,
UIWebViewDelegate
>
@property (nonatomic,copy) NSString *htmlName;
@property (nonatomic,strong) WKWebView *wkWebView;
@property (nonatomic,strong) UIWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.htmlName = @"test2";
    WKWebViewConfiguration *webViewConfig = [WKWebViewConfiguration new];
    //window.webkit.messageHandlers.webViewApp.postMessage
    //调用时name一定要保持一致
    [webViewConfig.userContentController addScriptMessageHandler:self name:@"webViewApp"];
    //在h5加载完成后注入js,改变h5背景颜色
    NSString *source = @"document.body.style.background = \"#777\";";
    [webViewConfig.userContentController addUserScript:[[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES]];
    WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 20, kScreenWidth, 500)
                                            configuration:webViewConfig];
    wkWebView.navigationDelegate = self;
    wkWebView.UIDelegate = self;
    wkWebView.hidden = YES;
    [wkWebView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
//    webView.backgroundColor = [UIColor redColor];
//    [self.view addSubview:wkWebView];
    self.wkWebView = wkWebView;
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 20, kScreenWidth, 500)];
    webView.delegate = self;
    webView.hidden = NO;
    [self.view addSubview:webView];
    
    NSString *path = [[NSBundle mainBundle] pathForResource:self.htmlName ofType:@"html"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL fileURLWithPath:path]];
    [webView loadRequest:request];
    self.webView = webView;
//    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.baidu.com"]]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSLog(@"webView加载完成:\n%@",webView.request.URL.absoluteString);
    // 获取当前页面的title
    NSString *title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    // 获取当前页面的url
    NSString *url = [webView stringByEvaluatingJavaScriptFromString:@"document.location.href"];
    //  当前页面高度
    NSString *height = [webView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"];

    //获取webView的jsContext方法
    JSContext *context = [webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    context.exceptionHandler = ^(JSContext *con, JSValue *exceptionValue) {
        NSLog(@"exceptionValue:%@", exceptionValue);
        con.exception = exceptionValue;
    };
    context[@"share"] = ^() {
        NSLog(@"+++++++Begin Log+++++++");
        NSArray *args = [JSContext currentArguments];
        
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
    //加法运算
    [context evaluateScript:@"function add(a, b) { return a + b; }"];
    JSValue *addValue = context[@"add"];
    NSLog(@"Func: %@", addValue);
    JSValue *sumValue = [addValue callWithArguments:@[@7, @21]];
    NSLog(@"Sum: %d",[sumValue toInt32]);
    
    //测试自定义对象
    TestJSObject *testObj = [TestJSObject new];
    context[@"testobject"] = testObj;
    
    [context evaluateScript:@"testobject.testNOParmaters()"];
    //JS中没有参数名称,任何的参数名称都会被转换为驼峰形式并且附加到函数名后
    [context evaluateScript:@"testobject.testParmatersParmater2('参数A','参数B')"];
}

#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"开始加载:%@",self.htmlName);
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"当内容开始返回时调用");
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"页面加载完成之后调用");
    //设置禁止选中
    [webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none';" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
    }];
    //获取webView高度
    [webView evaluateJavaScript:@"document.body.offsetHeight" completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        CGFloat height = [result floatValue];
        NSLog(@"height == %f", height);
    }];
    if([self.htmlName isEqualToString:@"test2"]){
        //方式二交互
        
    }
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"页面加载失败时调用");
}
// 接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"接收到服务器跳转请求之后调用");
}
// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"在收到响应后，决定是否跳转");
    decisionHandler(WKNavigationResponsePolicyAllow);
}
// 在发送请求之前，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSLog(@"在发送请求之前，决定是否跳转");
    NSURL *abcURL = navigationAction.request.URL;
    NSString *abcUrlStr = abcURL.absoluteString;
    NSLog(@"当前的获取URL == %@", abcUrlStr);
    if ([abcURL.scheme isEqualToString:@"firstclick"]) {
        //方式一交互
        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithCapacity:0];
        NSURLComponents *URLComponents = [NSURLComponents componentsWithString:abcUrlStr];
        NSArray *URLqueryItems = URLComponents.queryItems;
        if (URLComponents && URLqueryItems.count >0) {
            for (NSURLQueryItem *item in URLqueryItems) {
                [mutableDict setObject:item.value forKey:item.name];
            }
        }
//        [[[UIAlertView alloc] initWithTitle:mutableDict[@"title"]
//                                    message:mutableDict[@"content"]
//                                   delegate:nil
//                          cancelButtonTitle:@"好的"
//                          otherButtonTitles:nil] show];
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

#pragma mark - WKUIDelegate
//获取OC原生调用的JS alert方法
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    completionHandler();
    NSLog(@"WKWebView中OC调用JS方法:%@",message);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"title" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self presentViewController:alertController animated:YES completion:^{
    }];
}

#pragma mark - WKScriptMessageHandler
//提供接收网页消息的回调方法
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"message name:%@,body:%@",message.name,message.body);
}

#pragma mark - action
/**
 方式一:

 @param sender <#sender description#>
 */
- (IBAction)button1Clicked:(id)sender {
    self.htmlName = @"test1";
    NSString *path = [[NSBundle mainBundle] pathForResource:self.htmlName ofType:@"html"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL fileURLWithPath:path]];
    self.webView.hidden = YES;
    [self.webView removeFromSuperview];
    self.wkWebView.hidden = NO;
    [self.wkWebView removeFromSuperview];
    [self.view addSubview:self.wkWebView];
    [self.wkWebView loadRequest:request];
}

/**
 方式二:js模拟URL请求,利用webView的代理方法拦截请求

 @param sender <#sender description#>
 */
- (IBAction)button2Clicked:(id)sender {
    self.htmlName = @"test2";
    NSString *path = [[NSBundle mainBundle] pathForResource:self.htmlName ofType:@"html"];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL fileURLWithPath:path]];
    self.wkWebView.hidden = YES;
    [self.wkWebView removeFromSuperview];
    self.webView.hidden = NO;
    [self.webView removeFromSuperview];
    [self.view addSubview:self.webView];
    [self.webView loadRequest:request];
}
- (IBAction)JSButtonClicked:(id)sender {
    if([self.htmlName isEqualToString:@"test1"]){
        //方式一
        NSString *jsStr = [NSString stringWithFormat:@"showAlert('%@')",@"这里是JS中alert弹出的message"];
        //UIWebView的JS调用方式: stringByEvaluatingJavaScriptFromString
//        [self.wkWebView evaluateJavaScript:jsStr completionHandler:^(id _Nullable data, NSError * _Nullable error) {
//            NSLog(@"");
//        }];
        
        //手动调用JS方法给APP发送消息
        NSString *str = @"{'method' : 'showAlert','message' : 'wkWebView',}";
        [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"window.webkit.messageHandlers.webViewApp.postMessage(%@)",str] completionHandler:^(id _Nullable data, NSError * _Nullable error) {
            NSLog(@"可以通过手动调用js方法发送消息");
        }];
    }else if([self.htmlName isEqualToString:@"test2"]){
        //方式二
//        JSContext *context = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
//        NSString *textJS = @"showAlert('这里是JS中alert弹出的message')";
//        [context evaluateScript:textJS];
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"showAlert('%@')",@"这里是JS中alert弹出的message"]];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        WKWebView *wkWebView = (WKWebView *)object;
        NSLog(@"wkWebView:%.2f",wkWebView.estimatedProgress);
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //不释放时会导致交互对象内存常驻
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"webViewApp"];
}

- (void)dealloc
{
    [self.wkWebView removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
