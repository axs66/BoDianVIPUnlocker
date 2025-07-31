#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    NSString *urlStr = request.URL.absoluteString;

    // ✅ 开屏广告拦截
    if ([urlStr containsString:@"pgdt.gtimg.cn"] || [urlStr containsString:@"img4.kuwo.cn"]) {
        NSLog(@"🛑 拦截开屏广告请求: %@", urlStr);

        NSData *emptyData = [NSData data];
        NSURLResponse *fakeResponse = [[NSURLResponse alloc] initWithURL:request.URL
                                                                MIMEType:@"image/png"
                                                   expectedContentLength:0
                                                        textEncodingName:nil];
        completionHandler(emptyData, fakeResponse, nil);
        return nil;
    }

    // ✅ 拦截会员 JSON 字段并伪造
    return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
    if (data && [response.MIMEType containsString:@"application/json"]) {
        // 动态获取编码
        NSStringEncoding encoding = NSUTF8StringEncoding;
        if (response.textEncodingName) {
            CFStringRef cfEncoding = (__bridge CFStringRef)response.textEncodingName;
            encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(cfEncoding));
        }
        
        NSString *body = [[NSString alloc] initWithData:data encoding:encoding];
        if (body) {
            // 修复后的正则字典（包含 \s* 匹配空格）
            NSDictionary<NSString *, NSString *> *replacements = @{ /* 修正后的键值对 */ };
            
            for (NSString *pattern in replacements) {
                NSError *regexError;
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                     options:0
                                                                                       error:&regexError];
                if (!regex) {
                    NSLog(@"正则错误: %@", regexError);
                    continue;
                }
                body = [regex stringByReplacingMatchesInString:body
                                                        options:0
                                                          range:NSMakeRange(0, body.length)
                                                   withTemplate:replacements[pattern]];
            }
            
            NSData *modifiedData = [body dataUsingEncoding:encoding];
            completionHandler(modifiedData, response, error);
            return;
        }
    }
    completionHandler(data, response, error);
});
