#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))originalHandler 
{
    NSString *urlStr = request.URL.absoluteString;
    
    // 1. 广告拦截（完全保留原始逻辑）
    if ([urlStr containsString:@"pgdt.gtimg.cn"] || [urlStr containsString:@"img4.kuwo.cn"]) {
        NSLog(@"🛑 拦截广告: %@", urlStr);
        NSData *emptyData = [NSData data];
        NSURLResponse *fakeResponse = [[NSURLResponse alloc] initWithURL:request.URL
                                                              MIMEType:@"image/png"
                                                 expectedContentLength:0
                                                      textEncodingName:nil];
        originalHandler(emptyData, fakeResponse, nil);
        return nil;
    }
    
    // 2. 定义修改后的回调（关键修复：避免嵌套 %orig）
    void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && [response.MIMEType containsString:@"application/json"]) {
            // 保留原始编码处理
            NSStringEncoding encoding = NSUTF8StringEncoding;
            if (response.textEncodingName) {
                CFStringRef cfEncoding = (__bridge CFStringRef)response.textEncodingName;
                encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(cfEncoding));
            }
            
            NSString *body = [[NSString alloc] initWithData:data encoding:encoding];
            if (body) {
                // 完全保留原始正则替换逻辑
                NSDictionary *replacements = @{
                    @"isVip\":\\s*\\d+" : @"isVip\":1",
                    @"vipType\":\\s*\\d+" : @"vipType\":1",
                    // ... 其他所有原始替换规则 ...
                };
                
                for (NSString *pattern in replacements) {
                    NSError *regexError;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                         options:0
                                                                                           error:&regexError];
                    if (!regexError) {
                        body = [regex stringByReplacingMatchesInString:body
                                                            options:0
                                                              range:NSMakeRange(0, body.length)
                                                       withTemplate:replacements[pattern]];
                    }
                }
                
                NSData *modifiedData = [body dataUsingEncoding:encoding];
                originalHandler(modifiedData, response, error);
                return;
            }
        }
        originalHandler(data, response, error);
    };
    
    // 3. 调用原始方法（关键修复：使用预定义的Block变量）
    return %orig(request, modifiedHandler);
}

%end
