//
//  Interrupt1kHz.h
//
//  Created by bach on 15.09.09.
//  Copyright 2009 Prof. Michael Bach. All rights reserved.
//
//
//	History
//	=======
//
//	2011-11-22	this should be made into a full singleton
//


#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "AbsoluteTimeUtils.h"
#import "NIDAQX.h"



@interface Interrupt1kHz : NSObject


+ (void) setSampleIndex: (NSInteger) value;

+ (void) setSamplesPerSweep: (NSUInteger) value;
+ (NSUInteger) samplesPerSweep;

//+ (void) setNumberOfArtifacts: (NSUInteger) value;
+ (void) numberOfArtifactsReset;

+ (void) setBufferNumber: (NSUInteger) value;
+ (NSUInteger) bufferNumber;
+ (void) bufferToggle;

+ (CGFloat) voltageAtChannel: (NSUInteger) channel;

+ (CGFloat) maxVoltage;

+ (void) invalidate;


@end
