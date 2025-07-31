#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))originalHandler 
{
    NSString *urlStr = request.URL.absoluteString;
    
    // 1. 广告拦截
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
    
    // 2. 定义修改后的回调
    void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && [response.MIMEType containsString:@"application/json"]) {
            NSStringEncoding encoding = NSUTF8StringEncoding;
            if (response.textEncodingName) {
                CFStringRef cfEncoding = (__bridge CFStringRef)response.textEncodingName;
                encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(cfEncoding));
            }
            
            NSString *body = [[NSString alloc] initWithData:data encoding:encoding];
            if (body) {
                // 完整的替换规则字典
                NSDictionary *replacements = @{
                    @"isVip\":\\s*\\d+" : @"isVip\":1",
                    @"vipType\":\\s*\\d+" : @"vipType\":1",
                    @"payVipType\":\\s*\\d+" : @"payVipType\":1",
                    @"expireDate\":\\s*\\d+" : @"expireDate\":31587551944000",
                    @"payExpireDate\":\\s*\\d+" : @"payExpireDate\":31587551944000",
                    @"ctExpireDate\":\\s*\\d+" : @"ctExpireDate\":31587551944000",
                    @"actExpireDate\":\\s*\\d+" : @"actExpireDate\":31587551944000",
                    @"bigExpireDate\":\\s*\\d+" : @"bigExpireDate\":31587551944000",
                    @"nickname\":\\s*\".*?\"" : @"nickname\":\"破解技术支持\"",
                    @"lowPriceText\":\\s*\".*?\"" : @"lowPriceText\":\"永久会员已激活\"",
                    @"text\":\\s*\".*?\"" : @"text\":\"永久会员已激活\"",
                    @"fristVipBtnText\":\\s*\".*?\"" : @"fristVipBtnText\":\"永久会员已激活\"",
                    @"zcTips\":\\s*\".*?\"" : @"zcTips\":\"高品质MP3格式，下载后永久拥有\""
                };
                
                // 执行所有正则替换
                for (NSString *pattern in replacements) {
                    @autoreleasepool {
                        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                            options:0
                                                                                              error:nil];
                        if (regex) {
                            body = [regex stringByReplacingMatchesInString:body
                                                                options:0
                                                                  range:NSMakeRange(0, body.length)
                                                           withTemplate:replacements[pattern]];
                        }
                    }
                }
                
                NSData *modifiedData = [body dataUsingEncoding:encoding];
                originalHandler(modifiedData, response, error);
                return;
            }
        }
        originalHandler(data, response, error);
    };
    
    // 3. 调用原始方法
    return %orig(request, modifiedHandler);
}

%end
