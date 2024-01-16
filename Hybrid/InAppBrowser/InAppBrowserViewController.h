#ifndef InAppBrowser_h
#define InAppBrowser_h

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#endif /* InAppBrowser_h */

@interface InAppBrowserViewController : UIViewController <WKUIDelegate>

@property (nonatomic, strong) NSString *urlString;

@property (weak, nonatomic) IBOutlet WKWebView *webView;

- (IBAction) inAppBrowserViewClose:(id)sender;

@end
