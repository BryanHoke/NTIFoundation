//
//  NTICoverageFix.h
//  NTIFoundation
//
//  Created by Christopher Utz on 7/24/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

//We need fix a coverage related issue.  See..
//https://groups.google.com/forum/?fromgroups#!topic/cocoaheadsau/uJsj9uSociI


void MethodSwizzle(NSString* origClassName, SEL origSel, NSString* newClassName, SEL newSel);

@interface NTITestFixes : NSObject

/**
 * This fixes a problem related to an Apple implementation of a core unix api.
 */
FILE* fopen$UNIX2003(const char* filename, const char* mode);

size_t fwrite$UNIX2003(const void* ptr, size_t size, size_t nitems, FILE* stream);

@end

