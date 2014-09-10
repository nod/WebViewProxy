//
//  AppDelegate.m
//  ExampleApp_iOS
//
//  Created by Marcus Westin on 6/13/13.
//  Copyright (c) 2013 WebViewProxy. All rights reserved.
//

#import "AppDelegate.h"
#import "WebViewProxy.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    [self _setupProxy];
    [self _createWebView];
    
    return YES;
}

- (void) _createWebView {
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.window.bounds];
    [_window addSubview:webView];
//    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"WebViewContent" ofType:@"html"];
//    NSString* html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
//    [webView loadHTMLString:html baseURL:nil];

    [webView loadRequest:({
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://tagesschau.de/"]];
        req;
    })];
}

- (void) _setupProxy {
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:5];
    
    [WebViewProxy handleRequestsWithHost:@"www.google.com" path:@"/images/srpr/logo3w.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:req.URL] queue:queue completionHandler:^(NSURLResponse *netRes, NSData *data, NSError *netErr) {
            if (netErr) {
                return [res pipeError:netErr];
            } else if (((NSHTTPURLResponse*)netRes).statusCode >= 400) {
                return [res respondWithStatusCode:500 text:@"There was some sort of error :("];
            } else {
                [res respondWithData:data mimeType:@"image/png"];
            }
        }];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"intercept" path:@"/Galaxy.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Galaxy" ofType:@"png"];
        UIImage* image = [UIImage imageWithContentsOfFile:filePath];
        [res respondWithImage:image];
    }];
    

    
    [WebViewProxy handleRequestsMatchingTest:^BOOL(NSURL *url) {
        return [url.host isEqualToString:@"www.tagesschau.de"] /*&& [url.path isEqualToString:@"/foo" ] */;
    } handler:^(NSURLRequest *req, WVPResponse *res) {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:req.URL]
                                           queue:queue
                               completionHandler:^(NSURLResponse *netRes, NSData *data, NSError *netErr)
        {
            if (netErr) {
                return [res pipeError:netErr];
            } else if (((NSHTTPURLResponse*)netRes).statusCode >= 400) {
                return [res respondWithStatusCode:((NSHTTPURLResponse*)netRes).statusCode  text:@"There was some sort of error :("];
            } else if ([res.request.URL.path isEqualToString:@"/"]){
                NSString *webSiteString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSRange bodyRange = [webSiteString rangeOfString:@"<body class=\"tagesschau tsIndex\">"];
                
                
                NSArray *fragments = @[[webSiteString substringToIndex:bodyRange.length + bodyRange.location], [webSiteString substringFromIndex:bodyRange.length + bodyRange.location]];
                
                webSiteString = [NSString stringWithFormat:
                                                @"%@%@%@",
                                                fragments[0],
                                 @"<div style=\"height:300px; width:100%; text-align:center; vertical-align: middle;line-height: 300px\">manuel was here!</div>",
                                                fragments[1]
                                 ];
                
                
                [res respondWithData:[webSiteString dataUsingEncoding:NSUTF8StringEncoding] mimeType:netRes.MIMEType];
            }
            else {
                [res respondWithData:data mimeType:netRes.MIMEType];

            }
        }];
    }];
    
    NSError *error;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:@"http://www.tagesschau.de"];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [request setHTTPMethod:@"POST"];
    
    NSDictionary *mapData = [[NSDictionary alloc] initWithObjectsAndKeys: @"TEST IOS", @"name",
                             @"IOS TYPE", @"typemap",
                             nil];
    NSData *postData = [NSJSONSerialization dataWithJSONObject:mapData options:0 error:&error];
    [request setHTTPBody:postData];
    
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
    }];
    
    [postDataTask resume];

}

@end
