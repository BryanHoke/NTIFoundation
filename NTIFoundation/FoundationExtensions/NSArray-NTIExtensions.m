//
//  NSArray-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/07/15.
//  Copyright 2011 NextThought. All rights reserved.
//

#import "NSArray-NTIExtensions.h"
#import <OmniFoundation/OmniFoundation.h>


@implementation NSArray (NTIExtensions)

+(BOOL)isEmptyArray: (id)a
{
	return a == nil || [a isNull] || [a count] == 0;
}

+(BOOL)isNotEmptyArray: (id)a
{
	return ![self isEmptyArray: a];
}

+(NSArray *)ensureArray:(id)obj
{
	if(!obj){
		return nil;
	}
	
	if(![obj isKindOfClass: [NSArray class]]){
		obj = @[obj];
	}
	
	return obj;
}

- (BOOL)isEmpty
{
	return self.count == 0;
}

-(BOOL)notEmpty
{
	return self.count > 0;
}

-(id)firstObjectOrNil
{
	return [NSArray isEmptyArray: self]
	? nil
	: self.firstObject;
}

-(id)secondObject
{
	return [self objectAtIndex: 1];
}

-(id)lastObjectOrNil
{
	return [NSArray isEmptyArray: self]
			? nil
			: self.lastObject; 
}

-(id)lastNonNullObject
{
	id result = nil;
	for( NSInteger i = [self count] - 1; i >= 0; i-- ) {
		result = [self objectAtIndex: i];
		if( OFNOTNULL( result ) ) {
			break;
		}
	}
	
	return OFNOTNULL( result ) ? result : nil;
}

@end
