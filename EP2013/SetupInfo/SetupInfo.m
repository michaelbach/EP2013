//
//  SetupInfo.m
//  EP2013
//
//
//  2012-07-10 Read general setup information from "EP2013SetupInfo/SetupInfo.plist" (in "initialize")
//  Created by bach on 2011-10-31.
//  Copyright 2011 Universitäts-Augenklinik. All rights reserved.
//

#import "SetupInfo.h"
#import "MiscSingletons.h"


@implementation SetupInfo


static GLfloat _screenEyeDistanceInCentimeters = 114;
static GLfloat _screenWidthInCentimeters = 37.6;
//static GLfloat _screenHeightInCentimeters = 15;	// assuming square pixels we don't need this
static GLfloat _maxLuminance = 150;
static CGFloat _screenWidthInPixels, _screenHeightInPixels;
static CGFloat _screenWidthInDegrees, _screenHeightInDegrees;
static GLfloat _screenLeftInDegrees, _screenRightInDegrees, _screenBottomInDegrees, _screenTopInDegrees;


static CGDisplayCount _numDisplays;
static CGDirectDisplayID _displayID4operator, _displayID4stimulator;
static NSScreen *_screen4operator, *_screen4stimulator;

NSMutableArray* eyeArray;
NSMutableArray* positionArray;



static CGFloat _frameRateInHz = 60.0f;


//	"initialize" is only sent once to each class
+ (void)initialize {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	if (self == [SetupInfo class]) {
		_displayID4operator = 0;  _displayID4stimulator = 0;
		#define kMaxDisplaysWeAreInterstedIn 3
		CGDirectDisplayID displays[kMaxDisplaysWeAreInterstedIn];
		CGDisplayErr err = CGGetActiveDisplayList(kMaxDisplaysWeAreInterstedIn, displays, &_numDisplays);
		if (err != kCGErrorSuccess) return;
		if (_numDisplays > 0) {
			_displayID4operator = displays[0];  _displayID4stimulator = _displayID4operator;
			_screen4operator = [NSScreen mainScreen];  _screen4stimulator = [NSScreen mainScreen];

			if (_numDisplays > 1) {
				_displayID4stimulator = displays[1];
				_screen4stimulator = [[NSScreen screens] objectAtIndex: 1];
			}
		}
		//	NSLog(@"numberOfDisplays: %d, displayID4operator: %d, displayID4stimulator: %d", _numDisplays, _displayID4operator, _displayID4stimulator);

		NSMutableString *setupInfoFolderPath = [NSMutableString stringWithString: [MiscSingletons path2SetupInfoPList]];
		if ([setupInfoFolderPath length]>1) {	// we have found it, now we load the SetupInfo.plist file
		   NSDictionary *dict=[[NSArray arrayWithContentsOfFile:setupInfoFolderPath] objectAtIndex:0];
           _screenWidthInCentimeters = [MiscSingletons floatFromDict:dict forKey:@"screenWidthInCentimeters"];
           _maxLuminance = [MiscSingletons floatFromDict:dict forKey:@"maxLuminance"];
           
           NSArray *myArray;
           myArray = (NSArray*)[MiscSingletons objectFromDict:dict forKey:@"eyeArray"];
           if (myArray == nil) {
                eyeArray = [[NSMutableArray arrayWithCapacity: 4] retain];  
                [eyeArray addObject:@"OD"]; [eyeArray addObject:@"OS"];            
                [eyeArray addObject:@"OU"]; [eyeArray addObject:@"-"];   
           } else {
               eyeArray = [[NSMutableArray arrayWithCapacity: [myArray count]] retain];  
               for (NSUInteger i=0; i < [myArray count];++i) {
                   [eyeArray addObject:[myArray objectAtIndex:i]];
               }
           }
 
           myArray = (NSArray*)[MiscSingletons objectFromDict:dict forKey:@"positionArray"];
           if (myArray == nil) {
               positionArray = [[NSMutableArray arrayWithCapacity: [myArray count]] retain];  
               [positionArray addObject:@"Oz-FPz"]; [positionArray addObject:@"O1-FPz"];            
               [positionArray addObject:@"O2-FPz"]; [positionArray addObject:@"bip"];   
           } else {
               positionArray = [[NSMutableArray arrayWithCapacity: [myArray count]] retain];  
               for (NSUInteger i=0; i < [myArray count];++i) {
                   [positionArray addObject:[myArray objectAtIndex:i]];
               }
           }
       } else {
           NSRunAlertPanel(@"SetupInfo file not found. Filename:", @"EP2013SetupInfo/SetupInfo.plist", @"Ok", nil, nil);
       }
	   [SetupInfo recalculate];
	}
}

+ (NSString*) eyeAtIndex: (NSUInteger) index {
    return [eyeArray objectAtIndex:index];
}


+ (NSUInteger) eyeCount  {
    return [eyeArray count];
}


+ (NSString*) positionAtIndex: (NSUInteger) index {
    return [positionArray objectAtIndex:index];
}


+ (NSUInteger) positionCount  {
    return [positionArray count];
}


+ (void) recalculate {
	_screenWidthInPixels = CGDisplayPixelsWide(_displayID4stimulator);
	_screenHeightInPixels = CGDisplayPixelsHigh(_displayID4stimulator);
	
	_screenWidthInDegrees = [SetupInfo pixels2Degrees: _screenWidthInPixels];
	_screenHeightInDegrees = [SetupInfo pixels2Degrees: _screenHeightInPixels];
	
	_screenRightInDegrees = _screenWidthInDegrees / 2.0; _screenLeftInDegrees = -_screenRightInDegrees;
	_screenTopInDegrees = _screenHeightInDegrees / 2.0; _screenBottomInDegrees = -_screenTopInDegrees;
	
	//		NSLog(@"screenWidthInDegrees: %f, screenHeigtInDegrees: %f", _screenWidthInDegrees, _screenHeightInDegrees);
}


+ (NSUInteger) screenWidthInPixels {return _screenWidthInPixels;}
+ (NSUInteger) screenHeightInPixels {	//NSLog(@"SetupInfo>screenHeightInPixels: %li", _screenHeightInPixels);
	return _screenHeightInPixels;
}

+ (GLfloat) screenWidthInCentimeters {return _screenWidthInCentimeters;}
+ (void) setScreenWidthInCentimeters: (GLfloat) v {_screenWidthInCentimeters = v;}


//+ (GLfloat) screenHeightInCentimeters {return _screenHeightInCentimeters;}
//+ (void) setScreenHeightInCentimeters: (GLfloat) v {_screenHeightInCentimeters = v;}


+ (GLfloat) screenEyeDistanceInCentimeters {return _screenEyeDistanceInCentimeters;}
+ (void) setScreenEyeDistanceInCentimeters: (GLfloat) v {_screenEyeDistanceInCentimeters = v;}


+ (GLfloat) screenWidthInDegrees {return _screenWidthInDegrees;}
+ (GLfloat) screenHeightInDegrees {return _screenHeightInDegrees;}

+ (GLfloat) screenRightInDegrees {return _screenRightInDegrees;}
+ (GLfloat) screenLeftInDegrees {return _screenLeftInDegrees;}

+ (GLfloat) screenTopInDegrees {return _screenTopInDegrees;}
+ (GLfloat) screenBottomInDegrees {return _screenBottomInDegrees;}


+ (GLfloat) pixels2Degrees: (GLfloat) pixels {
	return (pixels * 180.0 / M_PI * atan(_screenWidthInCentimeters / _screenEyeDistanceInCentimeters) / _screenWidthInPixels);
}

// calculate pixels from degrees, but clamp to 1 or more pixels
+ (GLfloat) degrees2Pixels: (GLfloat) deg {
	return fmax(1.0f, deg / [SetupInfo pixels2Degrees: 1.0]);
}


+ (GLfloat) pixelSizeInDegrees {return [SetupInfo pixels2Degrees: 1.0];}


+ (GLfloat) maxLuminance {return _maxLuminance;}
+ (void) setMaxLuminance: (GLfloat) v {_maxLuminance = v;}


+ (CGDisplayCount) numberOfDisplays {	//	NSLog(@"%s, n=%d", __PRETTY_FUNCTION__, _numDisplays);
	return _numDisplays;
}


+(CGDirectDisplayID) displayID4operator {	//	NSLog(@"SetupInfo>displayID4operator %u", _displayID4operator);
	return _displayID4operator;
}


+(CGDirectDisplayID) displayID4stimulator {	// NSLog(@"SetupInfo>displayID4stimulator %u", _displayID4stimulator);
	return _displayID4stimulator;
}


+(NSScreen *) screen4operator {return _screen4operator;}
+(NSScreen *) screen4stimulator {return _screen4stimulator;}



+(CGFloat) frameRateInHz {return _frameRateInHz;}
+(void) setFrameRateInHz: (CGFloat) f {	//	NSLog(@"DisplayInfo>setFrameRateInHz: %f", f);
	_frameRateInHz = f;
}


+(NSUInteger) framesFromReversalrate: (CGFloat) rps {
	NSUInteger frames = round(_frameRateInHz / rps);
	if (frames < 1) frames = 1;
	//	NSLog(@"DisplayInfo>framesFromReversalrate: %d", frames);
	return frames;
}


+(NSUInteger) framesFromSeconds: (CGFloat) secs {
	return [self framesFromReversalrate: 1.0f / secs];
}


@end
