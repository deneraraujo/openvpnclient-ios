//
//  OpenVPNDhcpOptionEntry+Internal.h
//  Pods
//
//  Created by Dener Araújo on 06/09/20.
//

#import "OpenVPNDhcpOptionEntry.h"

#include <ovpnapi.hpp>

using namespace openvpn;

@interface OpenVPNDhcpOptionEntry (Internal)

- (instancetype)initWithDhcpOptionEntry:(ClientAPI::DhcpOptionEntry)entry;

@end
