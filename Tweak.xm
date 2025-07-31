#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                           completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))originalHandler 
{
    NSString *urlStr = request.URL.absoluteString;
    
    // 广告拦截
    if ([urlStr containsString:@"pgdt.gtimg.cn"] || [urlStr containsString:@"img4.kuwo.cn"]) {
        NSData *emptyData = [NSData data];
        NSURLResponse *fakeResponse = [[NSURLResponse alloc] initWithURL:request.URL
                                                              MIMEType:@"image/png"
                                                 expectedContentLength:0
                                                      textEncodingName:nil];
        originalHandler(emptyData, fakeResponse, nil);
        return nil;
    }
    
    // 创建修改后的 Handler
    void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && [response.MIMEType containsString:@"application/json"]) {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if (body) {
                body = [body stringByReplacingOccurrencesOfString:@"\"isVip\":0" withString:@"\"isVip\":1"];
                // 其他字段替换...
                NSData *modifiedData = [body dataUsingEncoding:NSUTF8StringEncoding];
                originalHandler(modifiedData, response, error);
                return;
            }
        }
        originalHandler(data, response, error);
    };
    
    return %orig(request, modifiedHandler);
}

%end
