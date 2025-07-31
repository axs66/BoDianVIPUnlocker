#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {

    NSString *urlStr = request.URL.absoluteString;

    // ✅ 开屏广告拦截
    if ([urlStr containsString:@"pgdt.gtimg.cn"] || [urlStr containsString:@"img4.kuwo.cn"]) {
        NSLog(@"🛑 拦截开屏广告请求: %@", urlStr);

        // 返回空响应
        NSData *emptyData = [NSData data];
        NSURLResponse *fakeResponse = [[NSURLResponse alloc] initWithURL:request.URL
                                                                MIMEType:@"image/png"
                                                   expectedContentLength:0
                                                        textEncodingName:nil];

        completionHandler(emptyData, fakeResponse, nil);
        return nil; // 阻止原始请求
    }

    // ✅ 拦截会员 JSON 字段并伪造
    return %orig(request, ^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && [response.MIMEType containsString:@"application/json"]) {
            NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

            if (body) {
                NSDictionary<NSString *, NSString *> *replacements = @{
                    @"isVip\":\\d+": @"isVip\":1",
                    @"vipType\":\\d+": @"vipType\":1",
                    @"payVipType\":\\d+": @"payVipType\":1",
                    @"expireDate\":\\d+": @"expireDate\":31587551944000",
                    @"payExpireDate\":\\d+": @"payExpireDate\":31587551944000",
                    @"ctExpireDate\":\\d+": @"ctExpireDate\":31587551944000",
                    @"actExpireDate\":\\d+": @"actExpireDate\":31587551944000",
                    @"bigExpireDate\":\\d+": @"bigExpireDate\":31587551944000",
                    @"nickname\":\".*?\"": @"nickname\":\"Axs技术支持\"",
                    @"lowPriceText\":\".*?\"": @"lowPriceText\":\"Axs提供会员服务\"",
                    @"text\":\".*?\"": @"text\":\"Axs提供会员服务\"",
                    @"fristVipBtnText\":\".*?\"": @"fristVipBtnText\":\"Axs提供会员服务\"",
                    @"zcTips\":\".*?\"": @"zcTips\":\"高品质MP3格式，下载后永久拥有。波点大会员每月获赠99999999999999998张珍藏下载券（永久有效，无限累积）\""
                };

                for (NSString *pattern in replacements) {
                    NSError *regexError = nil;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&regexError];
                    if (!regexError) {
                        body = [regex stringByReplacingMatchesInString:body
                                                                options:0
                                                                  range:NSMakeRange(0, body.length)
                                                           withTemplate:replacements[pattern]];
                    }
                }

                NSData *modifiedData = [body dataUsingEncoding:NSUTF8StringEncoding];
                completionHandler(modifiedData, response, error);
                return;
            }
        }

        // 默认返回
        completionHandler(data, response, error);
    }); // ✅ ←←← 这里原本缺失了闭合括号
}

%end
