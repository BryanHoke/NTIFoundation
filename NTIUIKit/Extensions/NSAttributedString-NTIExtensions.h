//
//  NSAttributedString-NTIExtensions.h
//  NTIFoundation
//
//  Created by Christopher Utz on 10/25/11.
//  Copyright (c) 2011 NextThought. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kNTIChunkSeparatorAttributeName @"NTIChunkSeparatorAttributeName"

@interface NSAttributedString(NTIExtensions)
//Methods for parsing objects to attributed strings and back the other way.  Should be independent of the
//chunking implementation
+(NSAttributedString*)attributedStringFromObject: (id)object;
+(NSAttributedString*)attributedStringFromObjects: (NSArray*)objects;
+(NSAttributedString*)attributedStringFromAttributedStrings: (NSArray*)attrStrings;
-(NSArray*)objectsFromAttributedString;

//Methods relating to chunking
-(NSArray*)attributedStringsFromParts;
-(NSAttributedString*)attributedStringByAppendingChunk: (NSAttributedString*)chunk;
-(NSAttributedString*)attributedStringByAppendingChunks: (NSArray*)chunks;
-(NSAttributedString*)attributedStringByReplacingRange: (NSRange)range withChunk: (NSAttributedString*)chunk;

/** Retrieves the character index within the receiver of a given attachment.
 * @param attachment The attachment whose character index should be retrieved.
 * @return The character index of |attachment| if it is found in the receiver; NSNotFound otherwise.
 */
- (NSUInteger)indexofAttachment: (id)attachment;

- (CGSize)sizeForWidth:(CGFloat)width
			 multiLine:(BOOL)isMultiLine;

@end
