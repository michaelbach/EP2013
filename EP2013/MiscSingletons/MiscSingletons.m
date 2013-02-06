//
//  MiscSingletons.m
//  EP2013
//
//  2012-07-09  dictFromPListFileArray, objectFromDict, floatFromDict: 
//              Newly created to derive parameters from Array of pList-Files (SetupInfo, StimulusSteppers) TM
//  Created by bach on 15.02.12.
//  Copyright 2012 Department of Ophthalmology, University Medical Center Freiburg. All rights reserved.
//

#import "MiscSingletons.h"


@implementation MiscSingletons


+ (NSString *) path2ApplicationContainer {
	//	NSString *path = [[[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier: @"de.michaelbach.ERG2007"] stringByDeletingLastPathComponent];
	NSString *path = [[[[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];	// NSLog(@"path %@", path);
	return path;
}


+ (NSString *) path2StimuliFolder {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *appPath = [MiscSingletons path2ApplicationContainer];
	NSMutableString *jumpAboveString = [NSMutableString stringWithCapacity: 20];
	NSMutableString *stimulusFolderPath = [NSMutableString stringWithCapacity: 50];

	BOOL found = NO;
	do {	// find the folder "EP2013Stimuli" upwards of this application
		[stimulusFolderPath appendFormat: @"%@/%@%@", appPath, jumpAboveString, @"EP2013Stimuli/"];
		found = [fileManager fileExistsAtPath: stimulusFolderPath];
		[jumpAboveString appendString: @"../"];
	} while ((!found) && (jumpAboveString.length < 3*10));	// allow maximal indirection of 10 folders

	if (!found) {
		[stimulusFolderPath setString:@"/Users/bach/Documents/Bach/EDIAG/EDV/EP2013/EP2013Stimuli/"];
		found = [fileManager fileExistsAtPath: stimulusFolderPath];
	}
	return (found ? stimulusFolderPath : @"");
}


+ (NSString *) path2SetupInfoPList {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *appPath = [MiscSingletons path2ApplicationContainer];
	NSMutableString *jumpAboveString = [NSMutableString stringWithCapacity: 20];
	NSMutableString *setupInfoPath = [NSMutableString stringWithCapacity: 50];
	BOOL found = NO;
	do {	// find the folder "EP2013SetupInfo" upwards of this application
		[setupInfoPath appendFormat: @"%@/%@%@", appPath, jumpAboveString, @"EP2013SetupInfo/SetupInfo.plist"];
		found = [fileManager fileExistsAtPath: setupInfoPath];
		[jumpAboveString appendString: @"../"];
	} while ((!found) && (jumpAboveString.length < 3*10));	// allow maximal indirection of 10 folders

	if (!found) {
		[setupInfoPath setString:@"/Users/bach/Documents/Bach/EDIAG/EDV/EP2013/EP2013SetupInfo/SetupInfo.plist"];
		found = [fileManager fileExistsAtPath: setupInfoPath];
	}
	return (found ? setupInfoPath : @"");
}



+ (NSString *) path2EPFileGivenEPNum: (int) epNum {
	// the EPNum ist preceded by leading zeros up to a length of 5: "EP00123.itx"
	return [[self path2ApplicationContainer] stringByAppendingPathComponent: [NSString stringWithFormat: @"ERG%05u.itx", epNum]];
}

+ (NSString *) date2YYYY_MM_DD: (NSDate *) theDate {
	return [theDate descriptionWithCalendarFormat:
			@"%Y-%m-%d" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

+ (NSString *) date2HH_MM_SS: (NSDate *) theDate {
	return [theDate descriptionWithCalendarFormat:
			@"%H:%M:%S" timeZone:nil locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

+ (char) blockCharFromNumber: (NSUInteger) blockNumber {
	return (char)(blockNumber + (NSUInteger)'A');
}
+ (NSUInteger) blockNumberFromChar: (char) blockChar {
	return ((NSUInteger)blockChar - (NSUInteger)'A');	
}

+ (NSString *) composeWaveNameFromBlockNum: (NSUInteger) blk andSequenceNum: (NSUInteger) seq andChannel: (NSUInteger) chn { //	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSMutableString *s = [NSMutableString stringWithString: @"bloc"];
	unichar cc[1];  cc[0] = [self blockCharFromNumber: blk];
	[s appendString: [NSString stringWithCharacters:cc length: 1]];
	[s appendString: @"seq"];  [s appendString: [[NSNumber numberWithInt:seq] stringValue]];
	[s appendString: @"chan"];  [s appendString: [[NSNumber numberWithInt:chn] stringValue]];
	//	N SLog(@"ERG2007>Saving>composeWaveNameWithBlockNum: %@", s);
	return s;
}



// the below is not really necessary because this only offers class functions and not instance is required xx
+ (MiscSingletons *)sharedMiscSingletons {
	static id sharedMiscSingletons = nil;
	if (sharedMiscSingletons == nil) {
		sharedMiscSingletons = [[self alloc] init];
	}
    return sharedMiscSingletons;
}


+ (NSDictionary *) dictFromPListFileArray: (NSMutableArray *) pListFileArray pListFileIndex: (NSUInteger) plindex dictIndex : (NSUInteger) dindex {
	NSDictionary *aDict = [[pListFileArray objectAtIndex: plindex] objectAtIndex: dindex];
	if (aDict == nil) {
		//NSRunAlertPanel(@"A stimulus parameter is missing, key:", key, @"Ok", nil, nil);
	}
	return aDict;
}

+ (NSObject*) objectFromDict: (NSDictionary *) theDict forKey: (NSString *) key {
	NSObject *anObject = [theDict objectForKey: key];
	//NSLog(@"key: %@, object: %@", key, anObject.description);
	return anObject;
}

+ (CGFloat) floatFromDict: (NSDictionary *) theDict forKey: (NSString *) key {
    return [(NSNumber *)[self objectFromDict:theDict forKey:key] floatValue];
}






@end
