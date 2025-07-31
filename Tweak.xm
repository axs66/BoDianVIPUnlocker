#import <Foundation/Foundation.h>

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))originalHandler 
{
    NSString *urlStr = request.URL.absoluteString;
    
    // 1. 广告拦截
    if ([urlStr containsString:@"pgdt.gtimg.cn"] || [urlStr containsString:@"img4.kuwo.cn"]) {
        NSData *emptyData = [NSData data];
        NSURLResponse *fakeResponse = [[NSURLResponse alloc] initWithURL:request.URL
                                                              MIMEType:@"image/png"
                                                 expectedContentLength:0
                                                      textEncodingName:nil];
        // 确保在主线程回调
        dispatch_async(dispatch_get_main_queue(), ^{
            originalHandler(emptyData, fakeResponse, nil);
        });
        return nil;
    }
    
    // 2. 安全处理JSON修改
    void (^modifiedHandler)(NSData *, NSURLResponse *, NSError *) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        @autoreleasepool {
            if (!data || error) {
                originalHandler(data, response, error);
                return;
            }
            
            // 仅处理application/json
            if ([response.MIMEType containsString:@"application/json"]) {
                NSError *jsonError;
                NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
                
                if (!jsonError && jsonDict) {
                    // 直接修改字典避免正则风险
                    [self safeModifyVIPInfo:jsonDict];
                    
                    // 重新序列化
                    NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:jsonDict options:0 error:nil];
                    if (modifiedData) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            originalHandler(modifiedData, response, error);
                        });
                        return;
                    }
                }
            }
            
            // 原始数据回调
            dispatch_async(dispatch_get_main_queue(), ^{
                originalHandler(data, response, error);
            });
        }
    };
    
    return %orig(request, modifiedHandler);
}

// 安全修改VIP字段（避免正则）
- (void)safeModifyVIPInfo:(NSMutableDictionary *)dict {
    // 数值型字段
    NSArray *numericKeys = @[@"isVip", @"vipType", @"payVipType", 
                           @"expireDate", @"payExpireDate", 
                           @"ctExpireDate", @"actExpireDate", @"bigExpireDate"];
    
    for (NSString *key in numericKeys) {
        if (dict[key]) {
            [dict setValue:@1 forKey:key]; // 所有状态设为1
        }
    }
    
    // 特殊长整型字段
    NSNumber *longDate = @31587551944000; // 3022年
    NSArray *dateKeys = @[@"expireDate", @"payExpireDate", @"ctExpireDate", @"actExpireDate", @"bigExpireDate"];
    for (NSString *key in dateKeys) {
        if (dict[key]) {
            [dict setValue:longDate forKey:key];
        }
    }
    
    // 字符串字段
    NSDictionary *stringValues = @{
        @"nickname": @"破解技术支持",
        @"lowPriceText": @"永久会员已激活",
        @"text": @"永久会员已激活",
        @"fristVipBtnText": @"永久会员已激活",
        @"zcTips": @"高品质MP3格式，下载后永久拥有"
    };
    
    [stringValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
        if (dict[key]) {
            [dict setValue:value forKey:key];
        }
    }];
}

%end
