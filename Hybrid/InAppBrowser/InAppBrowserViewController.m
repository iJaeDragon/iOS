#import <Foundation/Foundation.h>

#import "InAppBrowserViewController.h"

@implementation InAppBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addScriptMessageHandler:self name:@"appcall"];
    
    NSString *webViewUrl = _urlString;
    NSString *pageUrl = [NSString stringWithFormat:@"%@", webViewUrl];
    
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    
    self.webView.scrollView.bounces = NO; // 웹페이지를 벗어나지 않도록 설정
    
    self.webView.scrollView.showsVerticalScrollIndicator = NO; // 스크롤바 제거
    self.webView.scrollView.showsHorizontalScrollIndicator = NO; // 스크롤바 제거
    
    self.webView.allowsBackForwardNavigationGestures = YES;
    
    
    [self.webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:pageUrl]]];
    
}

-(void)CLOSE:(NSString*) resultData {
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction) inAppBrowserViewClose:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"bokjiroioscall"]) {
        // 파라미터 확인 파서
        NSRange openingBracket = [message.body rangeOfString:@"("];
        NSRange closingBrace = [message.body rangeOfString:@")"
                                                     options:NSBackwardsSearch
                                                       range:NSMakeRange(0, [message.body description].length)
                                                      locale:nil];
        
        NSString *callAppFunctionName = [message.body substringWithRange:NSMakeRange(0, openingBracket.location)];
        BOOL isParameterPresent = (openingBracket.location + 1) == closingBrace.location;
        
        if(isParameterPresent) { // 파라미터 없음
            [self performSelector:NSSelectorFromString(callAppFunctionName)];
        } else { // 파라미터 있음
            NSUInteger openingBracketLocation = openingBracket.location + 1;
            NSUInteger closingBraceLocation = closingBrace.location;
            
            NSString *parametersString = [message.body substringWithRange:NSMakeRange(openingBracketLocation, (closingBraceLocation - openingBracketLocation))];
            NSArray *parameters = [[parametersString stringByReplacingOccurrencesOfString:@" " withString:@""] componentsSeparatedByString:@","];
            
            [self performSelector:NSSelectorFromString([callAppFunctionName stringByAppendingString:@":"]) withObject:parameters];
        }
    }
}

// Handle the window.open request
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
    
    return false;
}

#pragma mark - WKUIDelegate

// JavaScript의 alert 처리
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"확인"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        completionHandler();
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

// JavaScript의 confirm 처리
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:@"확인"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        completionHandler(YES);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"취소"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        completionHandler(NO);
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

// JavaScript의 prompt 처리
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:prompt
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.text = defaultText;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"확인"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        completionHandler(textField.text);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"취소"
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        completionHandler(nil);
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

@end
