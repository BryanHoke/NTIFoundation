//
//  SocketIOTransport.m
//  NTIFoundation
//
//  Created by Christopher Utz on 9/19/11.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "SocketIOTransport.h"

@implementation SocketIOTransport
@synthesize nr_delegate;

-(id)initWithRootURL: (NSURL*)u andSessionId: (NSString*)sid;
{
	self = [super init];
	self->sessionId = [sid retain];
	self->rootURL = [u retain];
	return self;
}

-(void)connect
{

}

-(void)disconnect
{

}

+(NSString*)name
{
	return @"unknown";
}

-(NSURL*)urlForTransport
{
	return [self->rootURL URLByAppendingPathComponent: 
			[NSString stringWithFormat: @"%@/%@", [[self class] name], self->sessionId]];
}

-(void)logAndRaiseError: (NSError*)error
{
	NSLog(@"%@", [error localizedDescription]);
	if([self.nr_delegate respondsToSelector:@selector(transport:didEncounterError:)]){
		[self.nr_delegate transport: self didEncounterError: error];
	}
}

-(void)updateStatus: (SocketIOTransportStatus)s
{
	if(self->status == s){
		return;
	}
	self->status = s;
	
	NSLog(@"Transport status updated to %ld", s);
	
	if([self->nr_delegate respondsToSelector:@selector(transport:connectionStatusDidChange:)]){
		[self->nr_delegate transport: self connectionStatusDidChange: s];
	}
	
	if(self->status == SocketIOTransportStatusConnected){
		//When we move to connected we fire that we are ready for data
		if([self->nr_delegate respondsToSelector:@selector(transportIsReadyForData:)]){
			[self->nr_delegate transportIsReadyForData: self];
		}
	}
}

-(void)dealloc
{
	NTI_RELEASE(self->sessionId);
	NTI_RELEASE(self->rootURL);
	[super dealloc];
}

@end

@implementation SocketIOWSTransport

+(NSString*)name
{
	return @"websocket";
}

-(void)connect
{
	if(self->socket)
	{
		return;
	}
	
	NSURL* websocketURL = [self urlForTransport];
	
	self->socket = [[WebSocket7 alloc] initWithURL: websocketURL];
	self->socket.nr_delegate = self;
	[self->socket connect];
}

-(void)disconnect
{
	[self->socket disconnect];
}
 
-(void)websocket: (WebSocket7*)socket connectionStatusDidChange: (WebSocketStatus)wss
{
	NSLog(@"Websocket status updated to %ld", wss);
}

-(void)websocket: (WebSocket7*)socket didEncounterError: (NSError*)error
{
	if([self.nr_delegate respondsToSelector:@selector(transport:didEncounterError:)]){
		[self.nr_delegate transport: self didEncounterError: error];
	}
}

-(NSError*)createErrorWithCode: (NSInteger)code andMessage: (NSString*)message
{
	NSDictionary* userData = [NSDictionary dictionaryWithObject: message forKey: NSLocalizedDescriptionKey];
	
	return [NSError errorWithDomain: @"SocketIOWSTransport" code: code userInfo: userData];
}

-(BOOL)handlePacket: (SocketIOPacket*)p
{
	switch(p.type){
		case SocketIOPacketTypeConnect:
			[self updateStatus: SocketIOTransportStatusConnected];
			return YES;
		default:
			return NO;
	}
}

-(void)websocketDidRecieveData: (WebSocket7*)socket
{
	//There is data for us it better be a string on the websocket.  We need
	//todeque it, turn it into a packet and stuff it into our rQ
	id data = [self->socket dequeueRecievedData];
	
	if(!data){
		NSLog(@"Attempt to dequeueData in websocketDidReceiveData resulted in nil object.");
		return;
	}
	
	//We are promised to only be called when there is a full ws object (NSString (text), or NSData (binary))
	
	//SocketIOTransport only deals with NSString.  If we get a data we will try to turn it into a
	//string.  If we can't we bail
	NSString* dataString = data;
	if( [data isKindOfClass: [NSData class]] ){
		NSLog(@"WS Transport found an unexpected data object.  This will likely result in an error");
		dataString = [NSString stringWithData: data encoding: NSUTF8StringEncoding];
	}
	
	//We have what should be a socket io serialized packet. Turn it into a packet object
	SocketIOPacket* packet = [SocketIOPacket decodePacketData: dataString];
	
	//Do we do anything other than tell our delegate?  Do we even tell our delegate?
	if(!packet)
	{
		NSError* error = [self createErrorWithCode: 201 
										andMessage: 
						  [NSString stringWithFormat: 
						   @"Unable to create socket.io packet from string %@", dataString]];
		[self logAndRaiseError: error];
	}
	
	if(![self handlePacket: packet]){
	
		[self enqueueRecievedData: packet];
	
		//Now we inform our delegate that we have data
		if( [self.nr_delegate respondsToSelector: @selector(transportDidRecieveData:)] ){
			[self.nr_delegate transportDidRecieveData: self];
		}
	}
}

//Dequeue a packet to send, serialize it, and pass it down to the socket
-(BOOL)dequeueAndSend
{
	SocketIOPacket* packet = [self dequeueDataForSending];
	
	//No data to send?
	if(!packet)
	{
		return NO;
	}
	//Serialize this bad boy and pass it on
	NSString* serializedPacket = [packet encode];
	[self->socket enqueueDataForSending: serializedPacket];
	
	//We we have enqueued data down to the socket so we have room for more
	if( [self.nr_delegate respondsToSelector: @selector(transportIsReadyForData:)] ){
		[self.nr_delegate transportIsReadyForData: self];
	}
	return YES;
}

//This is annoying. We don't want to have to deal with this here.  Find a way to abstract it.
-(void)enqueueDataForSending:(id)data
{
	[super enqueueDataForSending: data];
	if(self->shouldForcePumpOutputStream){
		self->shouldForcePumpOutputStream = NO;
		[self dequeueAndSend];
	}
}

-(void)websocketIsReadyForData: (WebSocket7*)socket
{
	BOOL didSend = [self dequeueAndSend];
	self->shouldForcePumpOutputStream = !didSend;
}


-(void)dealloc
{
	NTI_RELEASE(self->socket);
	[super dealloc];
}

@end
