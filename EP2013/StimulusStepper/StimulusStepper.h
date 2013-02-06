//
//  StimulusStepper.h
//
//  Created by bach on 15.09.09.
//  Copyright 2009 Prof. Michael Bach. All rights reserved.
//
//	History
//	=======
//
// 2012-07-23 Implementation of new structure:
// 2012-05-14 Changes:
//             numberOfSequences -> combinationCounterMax (nomenclature)
//             stateInSequence -> stateInSequenceCombination
//             selectedSequence -> selectedSequenceCombination


#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "AbsoluteTimeUtils.h"
#import <CoreVideo/CVDisplayLink.h>
#import "Stimage.h"
#import "SetupInfo.h"
#import "SweepOperations.h"
#import "EDGSerial.h"
#import "StimageSequence.h"



/*///////////////////////////////////////////////////////////////////////////////////
 #define kMaxImagesPerStim			600
 #define kMaxSamples				4990
 // Structure describing all stimuli
 typedef struct  {
 short sweepsPerStimulus;						// number of sweeps per stimulus
 short imagesPerSweep;							// number of images whose sequence makes the stimulus along the sweep (mostly 2)
 short framesPerImage[kMaxImagesPerStim];		// duration to show the image
 unsigned char outByte[kMaxImagesPerStim];		// this allows a trigger output to change per image
 //	string name, keyText0, keyText1;
 bool symmetric, doTCirc;
 double luminance, contrast, elementSize, rate, stimTime1;
 bool test4artifacts[kMaxSamples];
 } stimulusDescriptionStruct, *stimulusDescriptionStructPtr, **stimulusDescriptionStructHdl;
 // Explanation 19.4.2005: A stimulus is described along a sweep. It consists of a series of images. 
 // There are only kMaxUniqueImagesPerStim different images, but kMaxImagesPerStim can be shown (re-use)
 // The translation is via imageSequence, so uniqueImageIndex = imageSequence[imageIndex]
 // The simplest case would be that imageSequence just contains the sequence 0, 1, 2, 3, …
 // The re-use is for stimuli with many many, partially identical pictures, e.g. for motion with rest periods or
 //	for binocularly different stimuli */


@interface NSObject (StimulusPaintingHandlers)
- (void) oglTarget_drawWithImage: (Stimage *) stimImage;
@end


@interface StimulusStepper : NSObject {
    NSMutableArray* allSequenceCombinationsNames;
    NSMutableArray* allSequenceCombinationsDicts;
    NSUInteger combinationCounterMax;
    NSUInteger selectedSequenceCombination;
	id _delegate4StimRenderingStimulator, _delegate4StimRenderingEcho;
}


@property (assign) id delegate4StimRenderingStimulator, delegate4StimRenderingEcho;
@property (readonly) NSUInteger combinationCounterMax;
@property (assign) NSUInteger selectedSequenceCombination;
@property (readonly) GLfloat videoRefreshPeriod;

- (void) selectSequenceCombination: (NSUInteger) iSeq;
- (NSString*) combinationName;
- (void) sequenceCombinationStart;

- (void) setCombinationRepeatCounterMax: (NSUInteger) counterMax;
- (NSUInteger) getSequenceCounterMax;
- (void) selectStimageNo: (NSUInteger) iStim inSequenceNo: (NSUInteger) iSeq;
- (StimageSequence*) selectedStimageSequence;
- (NSString*) sequenceName;
- (NSString*) stimageName;
- (BOOL) stimageSymmetry;
- (GLfloat) stimageContrast;
- (GLfloat) stimageLuminance;
- (GLfloat) stimageElementSizeInDeg;
- (NSUInteger) stimageDurationInFrames;
- (NSString*) getEyeForChannel:(NSUInteger) iChannel;
- (NSString*) getPositionForChannel:(NSUInteger) iChannel;

- (void) retraceHandler;

- (void) suspendGDCTasks;



@end
