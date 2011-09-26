//
//  SocketIOSocket.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SocketIOPacket.h"
#import "SocketIOTransport.h"
#import "NTIAbstractDownloader.h"

extern NSString* const SocketIOResource;
extern NSString* const SocketIOProtocol;

enum {
	SocketIOSocketStatusConnecting = 1,
	SocketIOSocketStatusConnected = 2,
	SocketIOSocketStatusDisconnecting = 3,
	SocketIOSocketStatusDisconnected = 4,
	SocketIOSocketStatusMax = SocketIOSocketStatusDisconnected,
	SocketIOSocketStatusMin = SocketIOSocketStatusConnecting
};
typedef NSInteger SocketIOSocketStatus;

@class SocketIOSocket;
@protocol SocketIOSocketStatusDelegate <NSObject>
-(void)socketDidConnect: (SocketIOSocket*)s;
-(void)socketDidDisconnect: (SocketIOSocket*)s;
-(void)socketDidDisconnectUnexpectedly: (SocketIOSocket*)s;
-(void)socketWillReconnect: (SocketIOSocket*)s;
-(void)socketIsReconnecting: (SocketIOSocket*)s;
-(void)socketDidReconnect: (SocketIOSocket*)s;
//If the error is not the result of a lower level transport error t may be null
-(void)socket: (SocketIOSocket*)socket didEncounterError: (NSError*)error inTransport: (SocketIOTransport*)t;
@end

//In addition to the below calls.  We will attempt to generate dynamic selectors for events.
//For example for the event chat_EnteredRoom we would attempt to call chat_EnteredRoom: (NSArray*)args;
//If the delegate does not perform the dynamic selector we will give it to didRecieveUnhandledEventNamed: name : args
@protocol SocketIOSocketEventDelegate <NSObject>
-(void)socket: (SocketIOSocket*)p didRecieveMessage: (NSString*)message;
-(void)socket:(SocketIOSocket*)p didRecieveUnhandledEventNamed: (NSString *)name withArgs: (NSArray*)args;
@end

@interface SocketIOSocket : OFObject{
@private
	NSURL* url;
	NSString* username;
	NSString* password;
	NSString* sessionId;
	NSInteger heartbeatTimeout;
	NSArray* serverSupportedTransports;
	NSInteger closeTimeout;
	SocketIOSocketStatus status;
	SocketIOTransport* transport;
	id nr_statusDelegate;
	NSMutableArray* eventDelegates;
	NTIDelegatingDownloader* handshakeDownloader;
	BOOL shouldBuffer;
	NSMutableArray* buffer;
	BOOL reconnecting;
	NSTimer* closeTimeoutTimer;
	NSUInteger reconnectAttempts;
	NSMutableArray* attemptedTransports;
	BOOL forceDisconnect;
}
@property (nonatomic, readonly) NSInteger heartbeatTimeout;
@property (nonatomic, assign) BOOL shouldBuffer;
@property (nonatomic, assign) id nr_statusDelegate;
-(id)initWithURL: (NSURL *)url andName: (NSString*)name andPassword: (NSString*)pwd;
-(BOOL)addEventDelegate: (id)eventDelegate;
-(BOOL)removeEventDelegate: (id)eventDelegate;
-(void)connect;
//Sends the packet via the selected transport or buffers it for transmission
-(void)sendPacket: (SocketIOPacket*)packet;
-(void)disconnect;
//Bascially delegate emethods but the socket is the only delegate the transport will need.
-(void)transport: (SocketIOTransport*)t connectionStatusDidChange: (SocketIOTransportStatus)status;
-(void)transport: (SocketIOTransport*)t didEncounterError: (NSError*)error;
-(void)transport: (SocketIOTransport*)t didRecievePayload: (NSArray*)payload;
@end
