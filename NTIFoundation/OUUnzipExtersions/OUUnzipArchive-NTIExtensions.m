//
//  OUUnzipArchive-NTIExtensions.m
//  Prealgebra
//
//  Created by Jason Madden on 2011/06/29.
//  Copyright 2011 NextThought. All rights reserved.
//
#import "OUUnzipArchive-NTIExtensions.h"

#import <OmniUnzip/OUUnzipEntry.h>


NSString* pathFromUrl( NSURL* url )
{
	return [url path];
}

@implementation OUUnzipArchive(NTIExtensions)

+(NSURL*)destinationFor: (OUUnzipEntry*)entry
				  under: (NSString*)name
				 within: (NSURL*)libraryDir
{
	NSURL* dest;
	if( [[entry name] hasPrefix: name] ) {
		dest = [libraryDir URLByAppendingPathComponent: [entry name]];
	}
	else if( [[[entry name] pathComponents] count] > 1 ) {
		NSMutableArray* comps = [[[entry name] pathComponents] mutableCopy];
		[comps replaceObjectAtIndex: 0 withObject: name];
		dest = [libraryDir URLByAppendingPathComponent: [NSString pathWithComponents: comps]];
	}
	else {
		dest = [[libraryDir URLByAppendingPathComponent: name] URLByAppendingPathComponent: [entry name]];
	}
	return dest;
}

-(BOOL)extractEntry: (OUUnzipEntry*)entry
				 to: (NSURL*)dest
			  error: (NSError**)outError
{
	BOOL result = NO;
	
	NSData* data = [self dataForEntry: entry error: outError];
	if( data ) {
		NSFileManager* fileManager = [NSFileManager defaultManager];
		//Create parent directories, since we skip all directory entries in 
		//the zip.
		[fileManager
		 createDirectoryAtPath: [pathFromUrl( dest ) stringByDeletingLastPathComponent]
		 withIntermediateDirectories: YES
		 attributes: nil
		 error: outError];
		//Create the file. Note that we remove an existing file (symlink)
		//so as not to overwrite something outside our directory
		[fileManager removeItemAtURL: dest error: NULL];
		result = [data writeToURL: dest atomically: NO];
		//Match the timestamp
		if( result ) {
			result = [fileManager setAttributes: [NSDictionary 
												  dictionaryWithObject: [entry date]
												  forKey: NSFileModificationDate]
								   ofItemAtPath: pathFromUrl( dest )
										  error: outError];
		}
	}
	
	return result;
}

+(NSURL*)extract: (NSURL*)archiveFile
			  to: (NSString*)name
		  within: (NSURL*)libraryDir
		progress: (NSProgress**)progress
		   error: (NSError**)outError
{
	NSString* path = pathFromUrl( archiveFile );
	OUUnzipArchive* archive = [[OUUnzipArchive alloc] initWithPath: path error: outError];
	if( !archive ) {
		return nil;
	}
	
	//OUUnzipArchive has the terrible habit of releasing itself on unzip
	//errors. Deal with that by keeping an extra retain
	BOOL result = YES;
	NSArray* entries = [archive entries];
	NSUInteger totalCount = [entries count];
	__block NSInteger worked = 0;
	
	if(*progress){
		(*progress).totalUnitCount = totalCount;
	}
	
	for( OUUnzipEntry* entry in entries ) {
		if( ![NSFileTypeRegular isEqual: [entry fileType]] ) {
			worked++;
			if(*progress){
				(*progress).completedUnitCount = worked;
			}
			continue;
		}
		//An autorelease pool around this loop is critical, because each
		//file is loaded in memory as autoreleased data.
		//TODO: Not sure how the auto-released out error is supposed to
		//be able to make it out of the autorelease block. This seems to be a 
		//clunky solution.
		NSError* outerError = nil;
		@autoreleasepool {
			NSError* localError = nil;
			NSURL* dest = [self destinationFor: entry under: name within: libraryDir];
			//Actually extract the entry
			result = [archive extractEntry: entry to: dest error: &localError];
			worked++;
			if(*progress){
				(*progress).completedUnitCount = worked;
			}
			if( localError ) {
				outerError = localError;
			}
		}
		if( outerError && outError ) {
			*outError = outerError;
		}
		if( !result ) {
			NSLog( @"WARNING: Failed to unzip %@", entry );
			break;
		}

	}
	
	NSURL* resultURL = nil;
	if( result ) {
		NSFileManager* fileManager = [NSFileManager defaultManager];
		//The second release in the non-error case.
		resultURL = [libraryDir URLByAppendingPathComponent: name isDirectory: YES];
		//And match the timestamp
		[fileManager setAttributes: [NSDictionary 
									 dictionaryWithObject: [NSDate date]
									 forKey: NSFileModificationDate]
					  ofItemAtPath: pathFromUrl( resultURL )
							 error: outError];
	}
	return resultURL; 
}
@end
