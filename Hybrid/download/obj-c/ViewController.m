
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler  {
  NSURL *requestUrl = navigationAction.request.URL;

  NSString* moveUrl = [NSString stringWithFormat:@"%@", requestUrl];
    
    NSArray* fileTypeArr = [[NSArray alloc] initWithObjects:
                            // 파일 확장자 리스트
                            @".jpg" , @".png" , @".gif"
                            , @".pdf" , @".hwp" , @".doc" , @".docx" , @".xls" , @".xlsx", @".ppt" , @".pptx"
                            , @".txt" , @".zip"
                            , @".mp3" , @".mp4", @".avi" , @".mov"
                            , nil];
    
    for(int i=0; i<fileTypeArr.count; i++) {
        if ([[moveUrl lowercaseString] rangeOfString:[fileTypeArr[i] lowercaseString]].location != NSNotFound) {
            
            [self fileDownload:moveUrl currentView:self.view];
                        
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
            
        }
    }
}


// plist 아래 내용을 추가해야함 !내 파일에서 다운로드한 파일을 관리하기 위함
// Supports opening documents in place : YES
// Application supports iTunes file sharing : YES
- (void)fileDownload:(NSString*) downloadUrl currentView:(UIView*) view {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @try {
            // 특정 디렉터리를 생성합니다
            NSString *dirName = @"/content-download";
            NSError *error;
            NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *dataPath = [docDir stringByAppendingString:dirName];
            if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
            }
            // --
            
            // Get the URL of the loaded resource
            NSURL *theResourcesURL = [NSURL URLWithString:downloadUrl]; // NSString to NSURL
            NSString *fileExtension = [theResourcesURL pathExtension];
            
            // Get the filename of the loaded resource from the UIWebView's request URL
            NSString *filename = [theResourcesURL lastPathComponent];
            NSLog(@"Filename: %@", filename);
            
            // Get the path to the App's Documents directory
            NSString *docPath = [self documentsDirectoryPath];
            
            // Combine the filename and the path to the documents dir into the full path
            NSString *pathToDownloadTo = [NSString stringWithFormat:@"%@/%@/%@", docPath, dirName, filename];
            
            // Load the file from the remote server
            NSData *tmp = [NSData dataWithContentsOfURL:theResourcesURL];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // UI 업데이트 등을 메인 스레드에서 수행
                if (tmp != nil) {
                    NSError *error = nil;
                    // Write the contents of our tmp object into a file
                    [tmp writeToFile:pathToDownloadTo options:NSDataWritingAtomic error:&error];
                    [view makeToast:[NSString stringWithFormat:@"'%@' 다운로드 진행중", filename]];
                    if (error != nil) {
                        NSLog(@"Failed to save the file: %@", [error description]);
                    } else {
                        [view makeToast:[NSString stringWithFormat:@"'%@' 다운로드 완료", filename]];
                    }
                } else {
                    // File could not be loaded -> handle errors
                    [view makeToast:[NSString stringWithFormat:@"다운로드 실패: 파일을 찾지 못했습니다."]];
                }
            });
        } @catch (NSException *exception) {
            // UI 업데이트를 메인 스레드에서 처리
            dispatch_async(dispatch_get_main_queue(), ^{
                [view makeToast:@"다운로드 중 오류가 발생했습니다."];
            });
        }
        
    });
}

- (NSString *)documentsDirectoryPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    return documentsDirectoryPath;
}
