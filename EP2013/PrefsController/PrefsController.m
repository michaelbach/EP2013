//
//  PrefsController.m
//
//  Created by bach on 2012-01-10.
//  Copyright 2012 Universitäts-Augenklinik. All rights reserved.
//

#import "PrefsController.h"
#import "edgKeyConstants.h"


@implementation PrefsController


// C string -> NSString
//- (NSString *) c2nss: (char *) inString { return [NSString stringWithFormat: @"%s", inString]; }


- (id)init {
    self = [super init];
    if (self) { //	NSLog(@"%s", __PRETTY_FUNCTION__);
			[[NSUserDefaults standardUserDefaults] setObject: @kCurrentVersionDate forKey: @kKeyVersion];
    }
    
    return self;
}

- (void)dealloc {
    [super dealloc];
}


- (CGFloat) unitsPerMicroVolt { 
	return [[NSUserDefaults standardUserDefaults] floatForKey: @kKeyUnitsPerMicroVolt];
}
- (void) setUnitsPerMicroVolt: (CGFloat) theValue {
    NSAssert(theValue > 0 && theValue <= 1, @"unitsPerMicroVolt was <= 0 or > 1");
    [[NSUserDefaults standardUserDefaults] setFloat:theValue forKey: @kKeyUnitsPerMicroVolt];
}


- (void) setEpNumber: (NSUInteger) theValue { // NSLog(@"EP2010>PrefsController>setEpNumber: %i\n", theValue);
	[[NSUserDefaults standardUserDefaults] setInteger:theValue forKey: @kKeyEPNumber];
}
- (NSUInteger) epNumber { //	NSLog(@"%s", __PRETTY_FUNCTION__);
	return [[NSUserDefaults standardUserDefaults] integerForKey: @kKeyEPNumber];
}


- (void) setBlockNumber: (NSUInteger) theValue { // NSLog(@"%s", __PRETTY_FUNCTION__);
	[[NSUserDefaults standardUserDefaults] setInteger:theValue forKey: @kKeyBlockNumber];
}
- (NSUInteger) blockNumber { //	NSLog(@"%s", __PRETTY_FUNCTION__);
	return [[NSUserDefaults standardUserDefaults] integerForKey: @kKeyBlockNumber];
}


@end
