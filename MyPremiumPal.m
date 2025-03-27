#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static IMP originalImplementation;
NSURLSessionDataTask* mpp_dataTaskWithRequest(NSURLSession *self, SEL _cmd, NSURLRequest *request, void (^completionHandler)(NSData*, NSURLResponse*, NSError*)) {
    if (![request.URL.absoluteString containsString:@"/graphql"]) {
        return ((NSURLSessionDataTask* (*)(NSURLSession*, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*)))originalImplementation)(self, _cmd, request, completionHandler);
    }

    void (^wrappedCompletionHandler)(NSData*, NSURLResponse*, NSError*) = ^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString *operationName = [request valueForHTTPHeaderField:@"X-APOLLO-OPERATION-NAME"];
        if (![operationName isEqualToString:@"GetSubscriptionSummary"]) {
            completionHandler(data, response, error);
            return;
        }
        
        NSError *jsonError;
        NSMutableDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&jsonError];
        if (jsonError) {
            NSLog(@"[MyPremiumPal] JSON parsing error: %@", jsonError);
            completionHandler(data, response, error);
            return;
        }
        
        NSMutableDictionary *subscriptionSummary = [[json valueForKeyPath:@"data.getSubscriptionSummary"] mutableCopy];
        if (subscriptionSummary) {
            // Set premium values
            [subscriptionSummary setValue:@"PREMIUM_PLUS" forKey:@"currentTier"];
            [subscriptionSummary setValue:@YES forKey:@"hasPremium"];
            
            // Modify features array
            NSArray *features = [subscriptionSummary objectForKeyedSubscript:@"features"];
            if ([features isKindOfClass:[NSArray class]]) {
                NSMutableArray *mutableFeatures = [features mutableCopy];
                for (NSInteger i = 0; i < [mutableFeatures count]; i++) {
                    NSMutableDictionary *feature = [[mutableFeatures objectAtIndex:i] mutableCopy];
                    [feature setValue:@"ENTITLED" forKey:@"entitlement"];
                    [feature setValue:@"PREMIUM_PLUS" forKey:@"subscriptionTier"];
                    [mutableFeatures replaceObjectAtIndex:i withObject:feature];
                }
                [subscriptionSummary setValue:mutableFeatures forKey:@"features"];
            }

            // Update the json object with modified subscription summary
            [[json valueForKeyPath:@"data"] setValue:subscriptionSummary forKey:@"getSubscriptionSummary"];
            
            NSError *serializationError;
            NSData *modifiedData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&serializationError];
            if (!serializationError) {
                completionHandler(modifiedData, response, error);
                return;
            } else {
                NSLog(@"[MyPremiumPal] JSON serialization error: %@", serializationError);
            }
        }
        
        completionHandler(data, response, error);
    };
    return ((NSURLSessionDataTask* (*)(NSURLSession*, SEL, NSURLRequest*, void (^)(NSData*, NSURLResponse*, NSError*)))originalImplementation)(self, _cmd, request, wrappedCompletionHandler);
}

__attribute__((constructor))
static void initialize(void) {    
    @try {
        Class NSURLSessionClass = NSClassFromString(@"NSURLSession");
        if (!NSURLSessionClass) {
            NSLog(@"[MyPremiumPal] Failed to find NSURLSession class!");
            return;
        }

        SEL originalSelector = @selector(dataTaskWithRequest:completionHandler:);
        Method originalMethod = class_getInstanceMethod(NSURLSessionClass, originalSelector);
        if (!originalMethod) {
            NSLog(@"[MyPremiumPal] Failed to find the original method!");
            return;
        }

        originalImplementation = method_getImplementation(originalMethod);
        class_replaceMethod(NSURLSessionClass, originalSelector, (IMP)mpp_dataTaskWithRequest, method_getTypeEncoding(originalMethod));
    } @catch (NSException *exception) {
        NSLog(@"[MyPremiumPal] Exception during initialization: %@", exception);
    }
}