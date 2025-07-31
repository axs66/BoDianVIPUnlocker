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
                NSDictionary<NSString *, NSString *> *replacements = @{
                    @"isVip\":\\s*\\d+" : @"isVip\":1",
                    @"vipType\":\\s*\\d+" : @"vipType\":1",
                    @"payVipType\":\\s*\\d+" : @"payVipType\":1",
                    @"expireDate\":\\s*\\d+" : @"expireDate\":31587551944000",
                    @"payExpireDate\":\\s*\\d+" : @"payExpireDate\":31587551944000",
                    @"ctExpireDate\":\\s*\\d+" : @"ctExpireDate\":31587551944000",
                    @"actExpireDate\":\\s*\\d+" : @"actExpireDate\":31587551944000",
                    @"bigExpireDate\":\\s*\\d+" : @"bigExpireDate\":31587551944000",
                    @"nickname\":\\s*\".*?\"" : @"nickname\":\"Axs技术支持\"",
                    @"lowPriceText\":\\s*\".*?\"" : @"lowPriceText\":\"Axs提供会员服务\"",
                    @"text\":\\s*\".*?\"" : @"text\":\"Axs提供会员服务\"",
                    @"fristVipBtnText\":\\s*\".*?\"" : @"fristVipBtnText\":\"Axs提供会员服务\"",
                    @"zcTips\":\\s*\".*?\"" : @"zcTips\":\"高品质MP3格式，下载后永久拥有。波点大会员每月获赠99999999999999998张珍藏下载券（永久有效，无限累积）\""
                };
                
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
}

%end
