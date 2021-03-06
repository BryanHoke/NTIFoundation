//
//  WebSockets.h
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import <OmniFoundation/OmniFoundation.h>
#import "SendRecieveQueue.h"

#define kNTIWebSocket7Origin @"http://ipad.nextthought.com"

enum {
	WebSocketStatusNew = 0,
	WebSocketStatusConnecting = 1,
	WebSocketStatusConnected = 2,
	WebSocketStatusDisconnecting = 3,
	WebSocketStatusDisconnected = 4,
	WebSocketStatusMax = WebSocketStatusDisconnected,
	WebSocketStatusMin = WebSocketStatusNew
};
typedef NSInteger WebSocketStatus;

@class WebSocket7;

@protocol WebSocketDelegate <NSObject>
-(void)websocket: (WebSocket7*)socket connectionStatusDidChange: (WebSocketStatus)status;
-(void)websocket: (WebSocket7*)socket didEncounterError: (NSError*)error;
-(void)websocketDidRecieveData: (WebSocket7*)socket;
-(void)websocketIsReadyForData: (WebSocket7*)socket;
@end

@class HandshakeResponseBuffer;
@class WebSocketResponseBuffer;

#define kNTIWebSocketReadBufferSize 1024

//Our implementation of the websocket spec v7
//http://tools.ietf.org/html/draft-ietf-hybi-thewebsocketprotocol-17
@interface WebSocket7 : SendRecieveQueue<NSStreamDelegate>{
@private
	NSString* key;
	NSInputStream* socketInputStream;
	NSOutputStream* socketOutputStream;

	WebSocketStatus status;
	id __weak nr_delegate;
	
	//Reading data
	uint8_t readBuffer[kNTIWebSocketReadBufferSize];
	HandshakeResponseBuffer* handshakeResponseBuffer;
	WebSocketResponseBuffer* socketRespsonseBuffer;
	
	//Writing data
	BOOL shouldForcePumpOutputStream;
	NSData* dataToWrite;
	NSUInteger dataToWriteOffset;
}
@property (nonatomic, weak) id nr_delegate;
@property (nonatomic, readonly) WebSocketStatus status;
-(id)initWithRequest: (NSURLRequest*)request;
-(void)connect;
-(void)disconnect;
-(void)kill;
@end
