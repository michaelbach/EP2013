//
//  SetupInfo.h
//  EP2010
//
//  Created by bach on 2011-10-31.
//  Copyright 2011 Universitäts-Augenklinik. All rights reserved.
//
//	History
//	=======
//
//	2012-03-02	moved more calculations here, added "screens" (not in use yet). Deactivated "screenHeightInCentimeters" (assume square pixels)
//	2012-01-11	combined SetupInfo & DisplayInfo
//	2011-12-27	added framesFromSeconds
//	2011-11-22	typed internal state variables as "static"
//

#import <Foundation/Foundation.h>


@interface SetupInfo : NSObject

+ (void) recalculate;

+ (NSUInteger) screenWidthInPixels;
+ (NSUInteger) screenHeightInPixels;

	+ (GLfloat) screenWidthInCentimeters;
+ (void) setScreenWidthInCentimeters: (GLfloat) v;

//+ (GLfloat) screenHeightInCentimeters;
//+ (void) setScreenHeightInCentimeters: (GLfloat) v;

+ (GLfloat) screenEyeDistanceInCentimeters;
+ (void) setScreenEyeDistanceInCentimeters: (GLfloat) v;

+ (GLfloat) pixelSizeInDegrees;

+ (GLfloat) screenWidthInDegrees;
+ (GLfloat) screenHeightInDegrees;


+ (GLfloat) screenRightInDegrees;
+ (GLfloat) screenLeftInDegrees;

+ (GLfloat) screenTopInDegrees;
+ (GLfloat) screenBottomInDegrees;


+ (GLfloat) pixels2Degrees: (GLfloat) pixels;
+ (GLfloat) degrees2Pixels: (GLfloat) deg; // calculate pixels from degrees, but clamp to 1 or more pixels


+ (GLfloat) maxLuminance;
+ (void) setMaxLuminance: (GLfloat) v;


+(CGDisplayCount) numberOfDisplays;

// displaying the stimulus
+(CGDirectDisplayID) displayID4stimulator;

// displaying the small version for the operator
+(CGDirectDisplayID) displayID4operator;

+(NSScreen *) screen4operator;
+(NSScreen *) screen4stimulator;

// framerate of the current stimulation display
+(CGFloat) frameRateInHz;
+(void) setFrameRateInHz: (CGFloat) f;


// utility function to go from frequency (or reversal rate) or time to number of frames
+(NSUInteger) framesFromReversalrate: (CGFloat) rps;
+(NSUInteger) framesFromSeconds: (CGFloat) secs;


// Access default eye and position information that was read from SetupInfo.pList
+ (NSString*) eyeAtIndex: (NSUInteger) index;
+ (NSUInteger) eyeCount;
+ (NSString*) positionAtIndex: (NSUInteger) index;
+ (NSUInteger) positionCount;


@end
