/*
//  Image4Stim.h
//  EP2010
//
//  2012-05-15 Change: durationInFrames -> frameCounterMax (see nomenclature in StimulusStepper)
//  Created by bach on 2011-10-31.
//  Copyright 2011 Universitäts-Augenklinik. All rights reserved.
//
 History
 =======
 
 2011-12-27	added "drawBasicHomogenous"
 
*/

#import <Foundation/Foundation.h>
#include <OpenGL/gl.h> 
#import "Globals.h"
#import "SetupInfo.h"


@interface Stimage : NSObject {
	NSString* stimagePatternName;
	NSUInteger stimagePatternID;
	GLfloat freqInHz, contrast, luminance, elementSizeInDeg;
	BOOL symmetry, topLeftHasForeColor;
	NSUInteger frameCounter4StimageMax;
}


@property (retain) NSString *stimagePatternName;
@property (assign) NSUInteger stimagePatternID;
@property (assign) GLfloat contrast;
@property (assign) GLfloat luminance;
@property (assign) GLfloat elementSizeInDeg;
@property (assign) BOOL symmetry;
@property (assign) BOOL topLeftHasForeColor;
@property (assign) NSUInteger frameCounter4StimageMax;


- (void) drawRect:(NSRect)rect;


@end
