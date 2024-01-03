// call! :  webkit.messageHandlers.bokjiroioscall.postMessage(link);
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