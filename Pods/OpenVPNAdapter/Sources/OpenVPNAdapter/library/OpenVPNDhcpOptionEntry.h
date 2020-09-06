//
//  OpenVPNDhcpOptionEntry.h
//  Pods
//
//  Created by Dener Araújo on 06/09/20.
//

#import <Foundation/Foundation.h>

@interface OpenVPNDhcpOptionEntry : NSObject

@property (nullable, readonly, nonatomic) NSString *type;
@property (nullable, readonly, nonatomic) NSString *address;

- (nonnull instancetype) init NS_UNAVAILABLE;

@end
