//
//  PurchaseObject.h
//  Capture
//
//  Created by Gary Barnett on 11/16/13.
//  Copyright (c) 2013 Gary Barnett. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

extern NSString *kReceiptBundleIdentifer;
extern NSString *kReceiptBundleIdentiferData;
extern NSString *kReceiptVersion;
extern NSString *kReceiptOpaqueValue;
extern NSString *kReceiptHash;
extern NSString *kReceiptInApp;
extern NSString *kReceiptOriginalVersion;
extern NSString *kReceiptExpirationDate;

extern NSString *kReceiptInAppQuantity;
extern NSString *kReceiptInAppProductIdentifier;
extern NSString *kReceiptInAppTransactionIdentifier;
extern NSString *kReceiptInAppPurchaseDate;
extern NSString *kReceiptInAppOriginalTransactionIdentifier;
extern NSString *kReceiptInAppOriginalPurchaseDate;
extern NSString *kReceiptInAppSubscriptionExpirationDate;
extern NSString *kReceiptInAppCancellationDate;
extern NSString *kReceiptInAppWebOrderLineItemID;

extern const NSString * global_bundleVersion;
extern const NSString * global_bundleIdentifier;


@interface PurchaseObject : NSObject <SKRequestDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver>
-(void)setup;
-(SKProduct *)product;

-(void)purchaseProduct:(SKProduct *)product;

+(PurchaseObject *)manager;

-(void)updatePurchaseStatus;
-(void)restorePurchases;
@end
