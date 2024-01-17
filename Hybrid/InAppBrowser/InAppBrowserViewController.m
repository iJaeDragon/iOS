#import <Foundation/Foundation.h>

#import "InAppBrowserViewController.h"

@implementation InAppBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    [configuration.userContentController addScriptMessageHandler:self name:@"InAppBrowserInterface"];
    
    
    NSString *customUserAgent = @" ios";
    configuration.applicationNameForUserAgent = customUserAgent;
    
    // configuration 적용
    self.webView = [[WKWebView alloc] initWithFrame:self.webView.frame configuration:configuration];
    [self.view addSubview:self.webView];
    
    self.webView.UIDelegate = self;
    self.webView.navigationDelegate = self;
    
    self.webView.scrollView.bounces = NO; // 웹페이지를 벗어나지 않도록 설정
    
    self.webView.scrollView.showsVerticalScrollIndicator = NO; // 스크롤바 제거
    self.webView.scrollView.showsHorizontalScrollIndicator = NO; // 스크롤바 제거
    
    self.webView.allowsBackForwardNavigationGestures = YES;
    
    #ifdef DEBUG
    if (@available(iOS 16.4, *)) {
        self.webView.inspectable = YES;
    }
    #endif
    
    NSString *webViewUrl = _urlString;
    NSString *pageUrl = [NSString stringWithFormat:@"%@", webViewUrl];
    
    [self.webView loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:pageUrl]]];
    
}

-(void)APP_IOSINAPPBROWSERCLOSE_CALL:(NSMutableArray*) resultData {
    UIViewController *parentVC = self.presentingViewController;
    
    SEL selector = NSSelectorFromString(@"inAppBrowserViewCloseHandler:");
    // 부모 창의 메서드 호출
    if ([parentVC respondsToSelector:selector]) {
        [parentVC performSelector:selector withObject:resultData];
    }
    
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction) inAppBrowserViewClose:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - WKUIDelegate

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:@"InAppBrowserInterface"]) {
        NSString *messageBody = message.body;
        // 파라미터 확인 파서
        NSRange openingBracket = [messageBody rangeOfString:@"("];
        NSRange closingBrace = [messageBody rangeOfString:@")"
                                                     options:NSBackwardsSearch
                                                       range:NSMakeRange(0, [messageBody description].length)
                                                      locale:nil];
        
        NSString *callAppFunctionName = [messageBody substringWithRange:NSMakeRange(0, openingBracket.location)];
        BOOL isParameterPresent = (openingBracket.location + 1) == closingBrace.location;
        
        if(isParameterPresent) { // 파라미터 없음
            [self performSelector:NSSelectorFromString(callAppFunctionName)];
        } else { // 파라미터가 존재하는 경우 처리 파서
            NSUInteger openingBracketLocation = openingBracket.location + 1;
            NSUInteger closingBraceLocation = closingBrace.location;
            
            NSString *parametersString = [messageBody substringWithRange:NSMakeRange(openingBracketLocation, (closingBraceLocation - openingBracketLocation))];
            
            NSMutableArray *parameters = [NSMutableArray array];
            
            for(;[parametersString length] > 1;) {
                if([[parametersString stringByReplacingOccurrencesOfString:@" " withString:@""] hasPrefix:@"',"]) {
                    parametersString = [parametersString substringWithRange:NSMakeRange(2, [parametersString length] - 2)];
                }
                
                // 외따옴표 시작
                NSRange startSingleQuote = [parametersString rangeOfString:@"'"];
                
                // startSingleQuote 위치가 0이 아닌경우 공백이 있다는걸로 간주
                if(startSingleQuote.location != 0) {
                    parametersString = [parametersString substringWithRange:NSMakeRange(startSingleQuote.location, [parametersString length] - startSingleQuote.location)];
                    startSingleQuote.location -= startSingleQuote.location;
                }
                
                // 외따옴표 종료
                NSRange endSingleQuote;
                
                int cycleCnt = 0;
                while(true) {
                    NSString *tmpCurrStr = [parametersString substringWithRange:NSMakeRange(startSingleQuote.location + 1, parametersString.length - 1)];
                    NSArray *singleQuotePositionArray = [self findPositionsOfCharacter:'\'' inString:tmpCurrStr];
                    
                    NSUInteger specificPosition = [singleQuotePositionArray[cycleCnt] unsignedIntegerValue];

                    NSRange tmpEndSingleQuote = NSMakeRange(specificPosition, 1);
                    
                    NSString *tmpCurrStrSpaceRemoveStr = [[parametersString substringWithRange:NSMakeRange(tmpEndSingleQuote.location + 1, parametersString.length - (tmpEndSingleQuote.location + 1))] stringByReplacingOccurrencesOfString:@" " withString:@""];
                    if([tmpCurrStrSpaceRemoveStr isEqual:@"'"] || [[tmpCurrStrSpaceRemoveStr substringWithRange:NSMakeRange(0, 2)] isEqual:@"',"]) {
                        endSingleQuote = tmpEndSingleQuote;
                        break;
                    } else {
                        ++cycleCnt;
                        continue;
                    }
                }
                
                NSString *currentIndexString = [parametersString substringWithRange:NSMakeRange(startSingleQuote.location + 1, endSingleQuote.location - startSingleQuote.location)];
                parametersString = [parametersString substringWithRange:NSMakeRange(endSingleQuote.location + 1, parametersString.length - (endSingleQuote.location + 1))];
                [parameters addObject: currentIndexString];
                
            }
            
            [self performSelector:NSSelectorFromString([callAppFunctionName stringByAppendingString:@":"]) withObject:parameters];
        }
    }
}

- (NSArray *)findPositionsOfCharacter:(unichar)character inString:(NSString *)inputString {
    NSMutableArray *positions = [NSMutableArray array];
    
    NSUInteger location = 0;
    while (location < inputString.length) {
        NSRange range = [inputString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:[NSString stringWithFormat:@"%c", character]] options:0 range:NSMakeRange(location, inputString.length - location)];

        if (range.location != NSNotFound) {
            [positions addObject:@(range.location)];
            location = range.location + 1;
        } else {
            break;
        }
    }
    
    return positions;
}

// Handle the window.open request
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
    
    return false;
}

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
