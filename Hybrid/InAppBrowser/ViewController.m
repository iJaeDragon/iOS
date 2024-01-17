// Handle the window.open request
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    //[[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    InAppBrowserViewController *inAppBrowserViewController = [storyboard instantiateViewControllerWithIdentifier:@"InAppBrowserView"];

    // 프로퍼티에 데이터 설정
    inAppBrowserViewController.urlString = navigationAction.request.URL;
    
    // 모달 프레젠테이션 스타일을 풀스크린으로 설정
    inAppBrowserViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:inAppBrowserViewController animated:NO completion:^{
        
    }];
    
    return false;
}

- (void)inAppBrowserViewCloseHandler:(NSMutableArray*) resultData {
    [self.webView evaluateJavaScript:[NSString stringWithFormat:@"%@('\"%@\"');", [resultData objectAtIndex:1], [resultData objectAtIndex:0]] completionHandler:^(NSString *result, NSError *error){
        
    }];
}
