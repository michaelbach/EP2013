//
//  StimulusStepper.m
//  StimulatorSimulator
//
//  
// 2012-07-23 Implementation of new structure:
//            Init: Information on all sequenceCombinations are read from pList-Files.
//                  This is used to generate the popupMenu elements in the user interface
//            selectSequenceCombinationNo: 
//                  Information from the Dictionaries are read and the structure of 
//                  sequenceCombination -> stimageSequences -> Stimages is initialized
//            retraceHandler:
//                  The structure sequenceCombination -> stimageSequences -> Stimages is
//                  used to generate the stimuli and to send notifications to EP2010AppDelegate
//  2012-05-15  Changes:
//              - selectedSequenceIndex -> selectedSequenceCombinationIndex
//              - selectSequenceNo -> selectSequenceCombinationNo
//              - combinationArray replaces sequenceArray 
//              - sequenceStart -> sequenceCombinationStart
//              - combinationCounterMax is derived from the pList-File (-> allSequenceCombinationsDicts)
//              - selectSequenceCombinationNo reads parameters from allSequenceCombinationsDicts,
//                  not from fixed stimulus conditions (like sequence_ISCEVStandard_atStep)
//	2011-10-24	converted to using displayLink
//	2009-09-15  Created by bach
//
//  Copyright 2009 Michael Bach. All rights reserved.
//

#import "StimulusStepper.h"
#import "SetupInfo.h"
#import "Interrupt1kHz.h"
#import "MiscSingletons.h"
#import "StimageSequence.h"
#import "SequenceCombination.h"


@implementation StimulusStepper


enum SequenceSteps {info=0, build};	// the sequenceStep "info" is used to build the list of possible sequences

static NSUInteger combinationRepeatCounter;
static NSInteger sequenceRepeatCounter, sequenceRepeatCounterMax;
static NSInteger sequenceCounter,sequenceCounterMax;
static NSInteger stimageCounter, stimageCounterMax;
static NSInteger frameCounter4Stimage, frameCounter4StimageMax;

static StimageSequence *theSequence;

static CVDisplayLinkRef displayLinkRef;
static dispatch_queue_t queue4StimRendering, queue4Averaging;
static AbsoluteTimeUtils *absTime;
static EDGSerial *serialPort;
static NSUInteger selectedSequenceCombinationIndex;
static StimageSequence *selectedStimageSequence;
static Stimage *neutralStimage, *selectedStimage;

static SequenceCombination *sequenceCombination;

@synthesize delegate4StimRenderingStimulator=_delegate4StimRenderingStimulator, delegate4StimRenderingEcho=_delegate4StimRenderingEcho;
@synthesize selectedSequenceCombination;


struct deltaStatisticsStruct {
	int64_t deltaValue;  NSUInteger deltaCount;
};
static int compareCountStatistics(void const *item1, void const *item2) {
	struct deltaStatisticsStruct const *count1 = item1;
	struct deltaStatisticsStruct const *count2 = item2;
	if (count1->deltaCount < count2->deltaCount) {
		return -1;
	} else if (count1->deltaCount > count2->deltaCount) {
		return 1;
	}
	return 0;
}
// The renderer output callback function. http://developer.apple.com/library/mac/#qa/qa1385/_index.html
static CVReturn myDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *now, const CVTimeStamp *outputTime, CVOptionFlags flagsIn, CVOptionFlags*flagsOut, void *displayLinkContext) {
#pragma unused (displayLink, now, outputTime, flagsIn, flagsOut, displayLinkContext)
    [(StimulusStepper*)displayLinkContext retraceHandler];	// displayLinkContext holds the "self" value so we can call from this thread
		
    return kCVReturnSuccess;
	//	all the stuff below no longer necessary because "[oglContext update]" solved all the timing problems…

//	NSLog(@"version: %u, videoTimeScale: %i, videoTime: %qd, hostTime: %qu, rateScalar: %f, videoRefreshPeriod: %qi, flags: %qu", outputTime->version, outputTime->videoTimeScale, outputTime->videoTime, outputTime->hostTime, outputTime->rateScalar, outputTime->videoRefreshPeriod, outputTime->flags);
//	NSLog(@"videoTime: %qd, hostTime: %qu", outputTime->videoTime, outputTime->hostTime);
//	*NOW: version: 0, videoTimeScale: 60000, hostTime: 0, rateScalar: 0.000000, videoRefreshPeriod: 4299262263296, rateScalar: 1.001209
//  *outputTime: version: 0, videoTimeScale: 60000, videoRefreshPeriod: 1072694358
//	NSLog(@"videoTime: %qd, frames: %i", now->videoTime, now->smpteTime.frames);
//subframes=0, subframeDivisor=0, counter=0, type=0, flags=0, hours=0, 
//	NSLog(@"now>videoTime: %qd, now>hostTime: %qu, op>videoTime: %qd, op>hostTime: %qu", now->videoTime, now->hostTime, outputTime->videoTime, outputTime->hostTime);
//	if (outputTime->videoTime - now->videoTime != 1001) 
//		NSLog(@"now>videoTime: %qd, now>hostTime: %qu, op>videoTime: %qd, op>hostTime: %qu", now->videoTime, now->hostTime, outputTime->videoTime, outputTime->hostTime);

/* Let's check whether we missed a frame, by the following rationale:
 • now->videoTime has something related to frame count in difficult to understand units
 • the difference (delta) to the previous value must always be the same, bar missed frames.
 • so make an ongoing statistic of deltas. If the present delta differs from the most frequent one, we assume it's a missed frame.
*/

#define kDeltaStatisticsN 3
	static struct deltaStatisticsStruct deltaStatistics[kDeltaStatisticsN];
	static bool firstTime = YES;
	if (firstTime) {	// need to reset the statistics once
		for (NSUInteger i = 0; i<kDeltaStatisticsN; ++i) {
			deltaStatistics[i].deltaValue = 0; deltaStatistics[i].deltaCount = 0;
		}
		firstTime = NO;
	}
	static int64_t oldVideoTime;  int64_t deltaVideoTime = now->videoTime - oldVideoTime;  oldVideoTime = now->videoTime;
	BOOL deltaFound = NO;	// let's check if this deltavalue is already in in our list of frequent ones
	for (NSUInteger i = 0; i<kDeltaStatisticsN; ++i) {
		NSUInteger j = kDeltaStatisticsN-i-1;	// we go backwards to the most likely hit will be first
		if (deltaStatistics[j].deltaValue == deltaVideoTime) {
			deltaFound = YES;  ++deltaStatistics[j].deltaCount; break;
		}
	}
	// sorting: http://blog.ablepear.com/2011/11/objective-c-tuesdays-sorting-arrays.html
	qsort(deltaStatistics, kDeltaStatisticsN, sizeof(struct deltaStatisticsStruct), compareCountStatistics);
	if (!deltaFound) {	// ah, a new value. Lets sort our current list and replace the lowest count with our present value
		deltaStatistics[0].deltaValue = deltaVideoTime;
		deltaStatistics[0].deltaCount = 1;
	}
//	for (NSUInteger i = 0; i<kDeltaStatisticsN; ++i) NSLog(@"%i, value: %qd, count: %u", i, deltaStatistics[i].deltaValue, deltaStatistics[i].deltaCount);
//	if (deltaVideoTime != deltaStatistics[kDeltaStatisticsN-1].deltaValue) NSLog(@"deltaVideoTime: %qd, expected: %qd", deltaVideoTime, deltaStatistics[kDeltaStatisticsN-1].deltaValue);
}


- (void) releaseSequenceCombination{
	if (sequenceCombination == nil) return;
	[sequenceCombination dealloc];  
    sequenceCombination = nil;
}


- (void) setCombinationRepeatCounterMax: (NSUInteger) counterMax {
    [sequenceCombination setCombinationRepeatCounterMax:counterMax];
}

- (void) updateSequenceCombinationInformation {
    NSUInteger nChannels = [sequenceCombination  channelCounterMax];
    
    NSDictionary* dict1 = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:nChannels], @"nChannels",
                          [NSNumber numberWithInt:[SetupInfo screenEyeDistanceInCentimeters]], @"screenEyeDistance",
                          [NSNumber numberWithInt:[sequenceCombination combinationRepeatCounterMax]],@"combinationRepeatCounterMax",nil];
    
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setNumberOfChannelsNotification" object: self userInfo:dict1]];
 
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setScreenEyeDistanceNotification" object: self userInfo:dict1]];

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setCombinationRepeatCounterMaxNotification" object: self userInfo:dict1]];
    
    for (NSUInteger iChannel = 0; iChannel < nChannels; ++iChannel) {
        NSDictionary* dict2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:iChannel], @"channel",
                              [sequenceCombination getEyeForChannel:iChannel], @"eye",
                              [sequenceCombination getPositionForChannel:iChannel],@"position",nil];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setEyeNotification" object: self userInfo:dict2]];
        [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setPositionNotification" object: self userInfo:dict2]];
    }
}


- (NSString *) selectSequenceCombinationNo: (NSUInteger) iSeqComb step: (NSUInteger) iStep {
	// iSeqComb within bounds?
    if (iSeqComb >= [allSequenceCombinationsNames count]) {
        return @"";
    } else {
        //-----------------------------------------------------------
        // We generate exactly one sequenceCombination instance. If is exists, we delete it first
        //-----------------------------------------------------------
        [self releaseSequenceCombination];
        sequenceCombination  = [[[SequenceCombination alloc] init] autorelease];
        
        //-----------------------------------------------------------
        // Stimulus definitions from  Dict combinationDictArray 
        // Item 0: dictionary for general parameters
        //-----------------------------------------------------------
        selectedSequenceCombinationIndex = iSeqComb;
        NSArray *combinationDictArray=[allSequenceCombinationsDicts objectAtIndex:selectedSequenceCombinationIndex];
        NSDictionary *theDict=[combinationDictArray objectAtIndex:0];
       // NSLog(@"First Dict: %@", [MiscSingletons objectFromDict: theDict forKey: @"description"]);

        [sequenceCombination setSequenceCounterMax:[combinationDictArray count]-1];
        [sequenceCombination setCombinationRepeatCounterMax:(NSUInteger)[MiscSingletons floatFromDict: theDict forKey: @"combinationRepeatCounterMax"]];

        [SetupInfo setScreenEyeDistanceInCentimeters: [MiscSingletons floatFromDict: theDict forKey: @"screenEyeDistanceInCentimeter"]];
        
        for (NSUInteger i = 0; i<4; ++i) {
            NSDictionary *ch = (NSDictionary*)[MiscSingletons objectFromDict: theDict forKey: [NSString stringWithFormat:@"channel%d", i]];
            if (ch != nil) {
                [sequenceCombination addEye:[MiscSingletons objectFromDict: ch forKey: @"eye"].description];
                [sequenceCombination addPosition:[MiscSingletons objectFromDict: ch forKey: @"position"].description];
            }
        }
        
        [self updateSequenceCombinationInformation];
         
         if (iStep == build) {
             for (NSUInteger iSequenceCounter = 0; iSequenceCounter < [sequenceCombination sequenceCounterMax]; ++iSequenceCounter) {
                // Read parameters for each stimageSequence from Dict and generate a stimageSequence instance
                theDict=[combinationDictArray objectAtIndex:(iSequenceCounter+1)];
  
                StimageSequence *stimageSequence;
                stimageSequence = [[[StimageSequence alloc] init] autorelease];
 
                // Transfer general parameters from Dict to stimageSequence instance
                [stimageSequence setSequenceName:[MiscSingletons objectFromDict: theDict forKey:@"sequenceName"].description];     
                [stimageSequence setSequenceRepeatCounterPre:(NSUInteger)[MiscSingletons floatFromDict: theDict forKey:@"sequenceRepeatCounterPre"]];    
                [stimageSequence setSequenceRepeatCounterMax:(NSUInteger)[MiscSingletons floatFromDict: theDict forKey:@"sequenceRepeatCounterMax"]];     
               
                // Transfer parameters for all stimages from Dict to stimageSequence instance
                NSArray *stimageArray=(NSArray*)[MiscSingletons objectFromDict: theDict forKey:@"stimageArray"];
                [stimageSequence setStimageCounterMax:[stimageArray count]];
                
                for (NSUInteger iStimageCounter = 0; iStimageCounter < [stimageSequence stimageCounterMax]; ++iStimageCounter) {
                    Stimage *theStimage = [[Stimage alloc] init];
                    [theStimage setSymmetry: YES];
 
                    NSDictionary *ch =(NSDictionary*)[stimageArray objectAtIndex:iStimageCounter];
                    NSString *stimPattern = [MiscSingletons objectFromDict: ch forKey: @"stimulusType"].description;
                    [theStimage setStimagePatternName:stimPattern];
                    
                    [theStimage setStimagePatternID:homogenous];
                    if ([stimPattern isEqualToString:@"homogenous"])	[theStimage setStimagePatternID:homogenous];
                    if ([stimPattern isEqualToString:@"checkerboard"])	[theStimage setStimagePatternID:checkerboard];
                    if ([stimPattern isEqualToString:@"gratingSquare"])	[theStimage setStimagePatternID:gratingSquare];
                    if ([stimPattern isEqualToString:@"gratingSine"])	[theStimage setStimagePatternID:gratingSine];
                    if ([stimPattern isEqualToString:@"scene"])			[theStimage setStimagePatternID:scene];
					
                    [theStimage setTopLeftHasForeColor: [[ch valueForKey:@"topLeftHasForeColor"] boolValue]];
                    [theStimage setElementSizeInDeg: [MiscSingletons floatFromDict: ch forKey: @"elementSizeInDeg"]];
                    [theStimage setLuminance: [MiscSingletons floatFromDict: ch forKey: @"meanLuminance"]];  
                    [theStimage setContrast: [MiscSingletons floatFromDict: ch forKey: @"contrast"]];  
                    [theStimage setFrameCounter4StimageMax: [SetupInfo framesFromSeconds: [MiscSingletons floatFromDict: ch forKey: @"stimageDurationInSec"]]];
                    
                    [stimageSequence addStimage:theStimage];
                    // NSLog(@"nStimages: %d", [stimageSequence getStimageCounterMax]);
                    //NSLog(@"Stimage: %@",[[stimageSequence stimageAtIndex:stimageCounter] stimagePatternName]);
                    [theStimage dealloc];
                }
                
                [sequenceCombination addSequence:stimageSequence];
                // NSLog(@"nStimageSequences: %d", [sequenceCombination getSequenceCounterMax]);
                [stimageSequence dealloc];
            }
        }
        return [allSequenceCombinationsNames objectAtIndex:selectedSequenceCombinationIndex];
    }
}

- (void) selectSequenceCombination: (NSUInteger) iSeqComb {
	[self selectSequenceCombinationNo: iSeqComb step: info];
}

- (NSString*) combinationName {
	return [allSequenceCombinationsNames objectAtIndex:selectedSequenceCombinationIndex];
}
@synthesize combinationCounterMax;

- (void) sequenceCombinationStart {
	[self selectSequenceCombinationNo:selectedSequenceCombinationIndex step:build];
/*	CVReturn error = CVDisplayLinkSetCurrentCGDisplay(displayLinkRef, [SetupInfo displayID4stimulator]);
	if(error != kCVReturnSuccess) {
		NSLog(@"CVDisplayLinkSetCurrentCGDisplay with error:%d", error); displayLinkRef = NULL;
	} */
	gEpState = epStatePausedSweep;
}

- (NSUInteger) getSequenceCounterMax {
    return [sequenceCombination sequenceCounterMax];
}


- (void) selectStimageNo: (NSUInteger) iStim inSequenceNo: (NSUInteger) iSeq {
    selectedStimageSequence = [sequenceCombination sequenceAtIndex:iSeq];
    selectedStimage = [selectedStimageSequence stimageAtIndex:iStim];
}

- (StimageSequence*) selectedStimageSequence {
    return  selectedStimageSequence;
}


- (NSString*) sequenceName {
	return [selectedStimageSequence sequenceName];
}

- (NSString*) stimageName {
	return [selectedStimage stimagePatternName];
}
- (BOOL) stimageSymmetry {
	return [selectedStimage symmetry];
}
- (GLfloat) stimageContrast {
	return [selectedStimage contrast];
}
- (GLfloat) stimageLuminance {
	return [selectedStimage luminance];
}
- (GLfloat) stimageElementSizeInDeg {
	return [selectedStimage elementSizeInDeg];
}
- (NSUInteger) stimageDurationInFrames {
	return [selectedStimage frameCounter4StimageMax];
}

- (NSString*) getEyeForChannel:(NSUInteger) iChannel {
    return [sequenceCombination getEyeForChannel:iChannel];
}

- (NSString*) getPositionForChannel:(NSUInteger) iChannel {
    return [sequenceCombination getPositionForChannel:iChannel];
}





- (void) establishDisplayLink {
	// http://developer.apple.com/library/mac/documentation/QuartzCore/Reference/CVDisplayLinkRef/CVDisplayLinkRef.pdf
	// http://developer.apple.com/library/mac/#documentation/QuartzCore/Reference/CVDisplayLinkRef/Reference/reference.html
	// http://developer.apple.com/library/mac/#qa/qa1385/_index.html
	// http://psychtoolbox-3.googlecode.com/svn-history/r2381/beta/PsychSourceGL/Source/OSX/Screen/PsychWindowGlue.c
	
	CVReturn error = CVDisplayLinkCreateWithActiveCGDisplays(&displayLinkRef);	// initally for all displays
	if(error != kCVReturnSuccess) {
		NSLog(@"DisplayLink created with error:%d", error); displayLinkRef = NULL; exit(-1);
	}
	error = CVDisplayLinkSetOutputCallback(displayLinkRef, myDisplayLinkCallback, self);
	if(error != kCVReturnSuccess)  {
		NSLog(@"CVDisplayLinkSetOutputCallback error:%d", error);  exit(-1);
	}
	error = CVDisplayLinkSetCurrentCGDisplay(displayLinkRef, [SetupInfo displayID4stimulator]);
	if(error != kCVReturnSuccess) {
		NSLog(@"CVDisplayLinkSetCurrentCGDisplay with error:%d", error); displayLinkRef = NULL; exit(-1);
	}
	error = CVDisplayLinkStart(displayLinkRef);
	if(error != kCVReturnSuccess) {
		NSLog(@"CVDisplayLinkStart error:%d", error);  exit(-1);
	}
	//NSLog(@"DisplayLink, refreshPeriod: %f", CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLinkRef));// doesn't give correct time now, but later
	
	CVDisplayLinkRetain(displayLinkRef);
}


/*
 STIMAGE: something to see, a "stimulus", an image/pattern (e.g. checkerboard) + luminance, contrast, elementsize, duration, …
 STIMAGE is described by its properties. Difficult images (e.g. mfERG) have to "delegate".
 STIMAGE duration is counted by frameCounter4Stimage and shown for frameCounter4StimageMax(=duration) frames
 STIMAGE is indexed by stimageCounter (in the STIMAGE_SEQUENCE) up to stimageCounterMax

 STIMAGE_SEQUENCE: a sequence of stimageCounterMax presentations of STIMAGEs. Example: 2 checkerboards with opposite phase.
 SWEEP: the response to a STIMAGE_SEQUENCE. SWEEPS are averaged and displayed.
 STIMAGE_SEQUENCE and SWEEP are used synonymously although they aren't really.
 STIMAGE_SEQUENCE is decribed by a sequenceName and contains an array stimageArray which holds stimageCounterMax STIMAGEs (indexed by stimageCounter)
 STIMAGE_SEQUENCE: repeated sequenceRepeatCounterMax times before moving to the next STIMAGE_SEQUENCE, repetitions are counted by sequenceRepeatCounter
 STIMAGE_SEQUENCE: indexed by sequenceCounter (in the SEQUENCE_COMBINATION) up to sequenceCounterMax

 SEQUENCE_COMBINATION: a sequential combination of STIMAGE_SEQUENCEs. For instance: a sequence of 2 STIMULI, each S xx checkerboards
 SEQUENCE_COMBINATION is decribed by a combinationName and contains
 - an array sequenceArray which holds sequenceCounterMax STIMAGE_SEQUENCEs (indexed by sequenceCounter)
 - an array eyeArray which holds eye information (e. g., "OD", "OS") for each channel
 - an array positionArray which holds position information (e. g., "Oz-Fpz") for each channel
 SEQUENCE_COMBINATION    There is only 1 SEQUENCE_COMBINATION active at any time – but its internal sequence may be randomized on repeating
 SEQUENCE_COMBINATION: repeated combinationRepeatCounterMax times, repetitions are counted by combinationRepeatCounter


 combinationArray • combinationRepeatCounter, combinationRepeatCounterMax
 sequenceArray • sequenceCounter, sequenceCounterMax, sequenceRepeatCounter, sequenceRepeatCounterMax
 stimageCounter, stimageCounterMax
 frameCounter4Stimage, frameCounter4StimageMax,
 */
-(id) init {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	allSequenceCombinationsNames = [[NSMutableArray arrayWithCapacity: 10] retain];
	allSequenceCombinationsDicts = [[NSMutableArray arrayWithCapacity: 5] retain];
	if ((self = [super init])) {
/*      Search for all pList-Files with an array of stimulus dictionaries. The pList-File must be in a directory "EP2010stimuli" upwards of this application*/
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSMutableString *stimulusFolderPath = [NSMutableString stringWithString: [MiscSingletons path2StimuliFolder]];
		if ([stimulusFolderPath length]>1) {	// we have found it, now look inside for *.plist files
			NSArray *folderContents = [NSArray arrayWithArray: [fileManager contentsOfDirectoryAtPath:stimulusFolderPath error: nil]];
			for (NSString *aFileName in folderContents) {
				if ([[aFileName pathExtension] isEqualToString: @"plist"]) {	// it's a plist file, so let's assume it is an array of stimulus dictionaries
					[allSequenceCombinationsNames addObject: [aFileName stringByDeletingPathExtension]];	// name of the sequence derives from the filename
					// NSLog(@"%@", [aFileName stringByDeletingPathExtension]);
					[allSequenceCombinationsDicts addObject: [NSArray arrayWithContentsOfFile: [stimulusFolderPath stringByAppendingPathComponent: aFileName]]]; // stim dict
					// NSLog(@"%@", [aFileName stringByDeletingPathExtension]);
				}
			}
		}

        if (allSequenceCombinationsNames.count <=0) {	// in case no stimulus file was found
            [allSequenceCombinationsNames addObject: @"none"];
            /*  ToDo: Standard-Bedingung, falls 
             [allSequenceCombinationsDicts addObject: 
                [NSArray arrayWithObject: 
                    [NSDictionary dictionaryWithObjectsAndKeys:@"PHOTOPIC", @kKeyStimName, @"LightAdapted3.0", @kKeyStimNameISCEV, 
                        [NSNumber numberWithFloat: 3], @kKeyFlashStrength, [NSNumber numberWithFloat: 1], @kKeyStimFrequency, @"W", @kKeyFlashColor,
                                                                     [NSNumber numberWithFloat: 10], @kKeyBackgroundLuminance,	@"B", @kKeyBackgroundColor,
                                                                     nil]]];*/
        }
        
        [self setSelectedSequenceCombination : 0];
        for (NSUInteger i = 0; i < allSequenceCombinationsNames.count; ++i) {	// let's select the standard stimulus sequence
            if ([[allSequenceCombinationsNames objectAtIndex: i] isEqualToString: @"Standard VEP"]) {
                [self setSelectedSequenceCombination: i];
                break;
            }
        }

		neutralStimage = [[[Stimage alloc] init] retain];
		[neutralStimage setStimagePatternID: homogenous];  [neutralStimage setLuminance: [SetupInfo maxLuminance] * 0.5];
		[neutralStimage setContrast: 0.0];  [neutralStimage setFrameCounter4StimageMax:[SetupInfo framesFromSeconds: 0.2f]];

		queue4StimRendering = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		queue4Averaging = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
		
		absTime = [[AbsoluteTimeUtils alloc] init];
				
		serialPort = [[EDGSerial alloc] init];	// Port for DTR + RTS control
		if ((serialPort) && ([serialPort numberOfSerialPorts] > 0)) [serialPort openPortNumber: 0];
        
        // combinationCounterMax can be derived from the pList Files (-> allSequenceCombinationsDicts)
        combinationCounterMax = [allSequenceCombinationsDicts count];
 		[self establishDisplayLink];
	}
	return self;
}


- (void)retraceHandler {  // NSLog(@"%s", __PRETTY_FUNCTION__);
    static NSUInteger oldEpState = epStateIdling;
	NSUInteger oldOldEpState = oldEpState;  
    oldEpState = gEpState;
	if (gEpState == epStateIdling) return;	// no stimulation to run

	if (gEpState != oldOldEpState) {	//	NSLog(@"state change");
		if (oldOldEpState == epStateIdling) {	//	NSLog(@"initialise");
			// just entered the recording begin, let's initialise everything concerned with stimulation
            frameCounter4Stimage = 0;  
			frameCounter4StimageMax = 0;	// so already the first comparison will lead to rendering of the stimulus
            stimageCounter = 0;
            stimageCounterMax = 0;
            sequenceRepeatCounter = 0;
            sequenceRepeatCounterMax = 0;
            sequenceCounter = 0;
            sequenceCounterMax = 0;
            combinationRepeatCounter = -1;  
  			[Interrupt1kHz setSamplesPerSweep: 0];
			[Interrupt1kHz setSampleIndex: -1];
			gEpState = epStateRecording;
		}
	}
	
	++frameCounter4Stimage;
	if (frameCounter4Stimage < frameCounter4StimageMax)  return;
	frameCounter4Stimage = 0;
	
	++stimageCounter;	// next STIM_IMAGE due, or are we fully done with this sweep?
	if (stimageCounter >= stimageCounterMax) {	// restart sweep
		stimageCounter = 0;
		[Interrupt1kHz setSampleIndex: -1];
		[Interrupt1kHz numberOfArtifactsReset];
		NSUInteger oldBufferNumber = [Interrupt1kHz bufferNumber];
		[Interrupt1kHz toggleBuffer];
		if (gSweepsRaw[oldBufferNumber].isArtifact) {
			NSLog(@"ARTIFACT");
            dispatch_async(queue4Averaging, ^{[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"incrementArtifactCountNotification" object: self]];});
			return;
		}
		dispatch_async(queue4Averaging, ^{
				[SweepOperations averageFromBufferNumber: oldBufferNumber forStimageSequence:sequenceCounter];
				if (gSweepsAveraged[sequenceCounter].nAverages > 1) {
					NSDictionary* sequenceDict = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:sequenceCounter] forKey:@"sequenceCounter"];
					[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"averagingDoneNotification" object: self userInfo:sequenceDict]];
				}
			}
		);

 		++sequenceRepeatCounter;
		if ((sequenceRepeatCounter >= sequenceRepeatCounterMax)) {
            ++sequenceCounter;
            if (sequenceCounter >= sequenceCounterMax) {
                sequenceCounter = 0;
                sequenceCounterMax = [sequenceCombination sequenceCounterMax];
                
                ++combinationRepeatCounter;
                if ( (combinationRepeatCounter >= [sequenceCombination combinationRepeatCounterMax]) ) {
                    gEpState = epStateIdling; // WE ARE DONE
                    [_delegate4StimRenderingStimulator oglTarget_drawWithImage: neutralStimage];
                    dispatch_async(queue4StimRendering, ^{ [_delegate4StimRenderingEcho oglTarget_drawWithImage: neutralStimage]; });
                    dispatch_async(queue4StimRendering, ^{ [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"recordingDoneNotification" object: self]];});
                    return;
                }
                NSDictionary* combinationDict = [NSDictionary dictionaryWithObject:
                                    [NSNumber numberWithInt:combinationRepeatCounter+1]
                                                                 forKey:@"combinationRepeatCounter"];                
                dispatch_async(queue4Averaging, ^{[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setCombinationRepeatCounterNotification" object:self userInfo:combinationDict]];});
            }  
             
            theSequence = [sequenceCombination sequenceAtIndex:sequenceCounter];
            sequenceRepeatCounterMax = [theSequence sequenceRepeatCounterMax];
            sequenceRepeatCounter = -[theSequence sequenceRepeatCounterPre];
            stimageCounterMax = [theSequence stimageCounterMax];

        }
        NSDictionary* sweepDict = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:sequenceRepeatCounter+1] forKey:@"sweepCounter"];
		dispatch_async(queue4Averaging, ^{[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setSweepCounterNotification" object: self userInfo:sweepDict]];});

        NSDictionary* sequenceDict = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:sequenceCounter+1] forKey:@"sequenceCounter"];                
		dispatch_async(queue4Averaging, ^{[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName: @"setSequenceCounterNotification" object: self userInfo:sequenceDict]];});
	}
    
    Stimage *theStimage;
    theStimage = [theSequence stimageAtIndex:stimageCounter];
    frameCounter4StimageMax = [theStimage frameCounter4StimageMax];
    
//   NSLog(@"StimageSequences: %@", [theSequence sequenceName]);
// NSLog(@"DisplayLink, refreshPeriod: %f", CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLinkRef));

	id currentStimImage = theStimage;
    
	[serialPort setDTR: YES];
	//[absTime reset];	// are we drawing the display fast enough?
	[_delegate4StimRenderingStimulator oglTarget_drawWithImage: currentStimImage];// calls drawWithImage4Stim in "OGLTargetMain"
	dispatch_async(queue4StimRendering, ^{ [_delegate4StimRenderingEcho oglTarget_drawWithImage: currentStimImage]; });
	//[absTime logMilliseconds];	// are we drawing the display fast enough?
	[serialPort setDTR: NO];
}


- (GLfloat) videoRefreshPeriod {
	return CVDisplayLinkGetActualOutputVideoRefreshPeriod(displayLinkRef);
}


- (void) suspendGDCTasks {
	dispatch_suspend(queue4StimRendering);  //dispatch_release(queue4StimRendering);
	dispatch_suspend(queue4Averaging);  //dispatch_release(queue4StimRendering);
}


- (void) dealloc {	// NSLog(@"%s", __PRETTY_FUNCTION__);
	CVDisplayLinkStop(displayLinkRef);  CVDisplayLinkRelease(displayLinkRef);
	[self suspendGDCTasks];
	[neutralStimage release];
	[self releaseSequenceCombination];
	[super dealloc];
}



@end
