//
//  EPAppDelegate.m
//  EP2013
//
//  2012-07-25 saveAverages: Added a for-loop to save the sweeps for each stimageSequence
//             some changes to store combination names, sequence names, stimage names etc.
//  2012-07-24 updateAverages shows averaged sweeps for current stimageSequence
//  2012-07-23 New notifications to update user interface (currentCombinationRepeatCounter,
//              currentSequence, combinationRepeatCounterMax, etc.
//              popupEyes and popupPositions get their defauls values from SetupInfo.pList file
//  Created by bach on 13.01.10.
//  Copyright 2010 Universitäts-Augenklinik. All rights reserved.
//

#import "EPAppDelegate.h"
#import "PrefsController.h"
#import "edgKeyConstants.h"
#import "SetupInfo.h"
//#import "RCAmp.h"
#import "MiscSingletons.h"
#import "SequenceCombination.h"
#import "StimageSequence.h"


@implementation EPAppDelegate


static PrefsController*	prefsController;
static Camera2 *camera;
static Interrupt1kHz *interrupt1kHz;
static StimulusStepper *stimStepper;
static OGLTargetMain *oglTargetMain;
static dispatch_source_t timerGCDOsci;
static Oscilloscope3 *avTrace;
//static RCAmp *rcAmp;
static NSArray *popupEyes, *popupPositions;
static NSUInteger _numberOfChannelsMax;
static NSWindow *stimScreenWindow;

@synthesize operatorWindow;



- (NSUInteger) numberOfChannels {
	return gNumberOfChannels;
}
- (void) setNumberOfChannels: (NSUInteger) channels {
	//	if (channels > [rcAmp maxNumberOfChannels]) channels = [rcAmp numberOfChannels];
	//	[rcAmp setNumberOfChannels: channels];
	[osci setNumberOfTraces: channels];  [popupNumberOfChannels_outlet selectItemAtIndex: channels-1];
	gNumberOfChannels = channels;
	
	for (NSUInteger iChan = 0; iChan < [popupEyes count]; ++iChan) {
		[[popupEyes objectAtIndex: iChan] setTransparent: (iChan>=channels)];
		[[popupPositions objectAtIndex: iChan] setTransparent: (iChan>=channels)];
	}
}
- (IBAction) popupNumberOfChannels_action:(id)sender {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (sender)
	[self setNumberOfChannels: [sender indexOfSelectedItem]+1];
}



- (IBAction) combinationRepeatCounterMax_action:(id)sender {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (sender)
	[stimStepper setCombinationRepeatCounterMax: [[sender title] integerValue]];
}


@synthesize currentCombinationRepeatCounter;
@synthesize currentSequence;
@synthesize currentSweep;
@synthesize currentArtifacts;
@synthesize combinationRepeatCounterMax;

- (void) indicateRecording: (BOOL) b {
	static BOOL oldB = NO;  if (b == oldB) return;  oldB = b;
	if (b)	[boxIndicator1_outlet setFillColor: [NSColor redColor]];
	else	[boxIndicator1_outlet setFillColor: [NSColor colorWithDeviceWhite: 1.0 alpha:1.0]];
}


- (void) setAmplifierInputOpenTo: (BOOL) state {
	if (state) {
		[buttonInput_outlet setTitle: @"Input: Ø"];
		//		[rcAmp select_VEPtr_default];
	} else {
		[buttonInput_outlet setTitle: @"Input: O"];
		//		[rcAmp setOpenTo: NO];
	}
}


////////////////////////////////////////////////////////////////////////////////////
//// notification handlers
- (void) updateAverages:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    NSUInteger sequenceCounter = [[dict objectForKey:@"sequenceCounter"] intValue];
	
	CGFloat f = 0.05f*gSweepsAveraged[sequenceCounter].nAverages;
	if (f>0) [avTrace setFullscale: f];
	NSUInteger nPoints = min([avTrace width], [Interrupt1kHz samplesPerSweep]);
	for (NSUInteger iChannel = 0; iChannel < gNumberOfChannels; ++iChannel) {
		//if (!isInCriticalSection)  <– removed 2012-04-16
		[avTrace setTrace: iChannel toCGFloatArray: (&gSweepsAveraged[sequenceCounter].sweep[iChannel][0]) nSamples: nPoints];
	}
}


- (void) recordingDone:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
	[self saveAverages];
	//	[buttonRetrievePIZ_outlet setEnabled: NO]; [buttonPrevERG_outlet setEnabled: NO];
	[fieldEpNum_outlet setEnabled: NO]; [fieldSubjectName setEnabled: NO]; [fieldSubjectPIZ setEnabled: NO]; [dateFieldBirthDate setEnabled: NO];
	[fieldAcuityOD setEnabled: NO]; [fieldAcuityOS setEnabled: NO]; [fieldReferrer setEnabled: NO]; [fieldDiagnosis setEnabled: NO];
	unichar cc[1];  cc[0] = [[fieldBlockNum_outlet stringValue] characterAtIndex:0] + 1;
	[fieldBlockNum_outlet setStringValue: [NSString stringWithCharacters:cc length: 1]];
    
    [self setCurrentCombinationRepeatCounter:0];
    [self setCurrentSweep:0];
    [self setCurrentArtifacts:0];
    [self setCurrentSequence:0];
}


- (void) setCombinationRepeatCounterNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    [self setCurrentCombinationRepeatCounter: [[dict objectForKey:@"combinationRepeatCounter"] intValue]];
}

- (void) setSequenceCounterNotification:(NSNotification *)aNotification  {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    [self setCurrentSequence: [[dict objectForKey:@"sequenceCounter"] intValue]];
}


- (void) setSweepCounterNotification:(NSNotification *)aNotification  {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    [self setCurrentSweep: [[dict objectForKey:@"sweepCounter"] intValue]];
}


- (void) setArtifactCounterNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    [self setCurrentArtifacts: [[dict objectForKey:@"artifactCounter"] intValue]];
}

- (void) setNumberOfChannelsNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    [self setNumberOfChannels: [[dict objectForKey:@"nChannels"] intValue]];
}

- (void) setPositionNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    NSInteger iChannel = [[dict objectForKey:@"channel"] intValue];
    switch (iChannel) {
        case 0:
            [popupPos00_outlet selectItemWithTitle:[dict objectForKey:@"position"]];
            break;
        case 1:
            [popupPos01_outlet selectItemWithTitle:[dict objectForKey:@"position"]];
            break;
        case 2:
            [popupPos02_outlet selectItemWithTitle:[dict objectForKey:@"position"]];
            break;
        case 3:
            [popupPos03_outlet selectItemWithTitle:[dict objectForKey:@"position"]];
            break;
        case 4:
            [popupPos04_outlet selectItemWithTitle:[dict objectForKey:@"position"]];
            break;
            
        default:
            break;
    }
}

- (void) setEyeNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    NSInteger iChannel = [[dict objectForKey:@"channel"] intValue];
    switch (iChannel) {
        case 0:
            [popupEye00_outlet selectItemWithTitle:[dict objectForKey:@"eye"]];
            break;
        case 1:
            [popupEye01_outlet selectItemWithTitle:[dict objectForKey:@"eye"]];
            break;
        case 2:
            [popupEye02_outlet selectItemWithTitle:[dict objectForKey:@"eye"]];
            break;
        case 3:
            [popupEye03_outlet selectItemWithTitle:[dict objectForKey:@"eye"]];
            break;
        case 4:
            [popupEye04_outlet selectItemWithTitle:[dict objectForKey:@"eye"]];
            break;
            
        default:
            break;
    }
}

- (void) setScreenEyeDistanceNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    NSInteger eyeDistance = [[dict objectForKey:@"screenEyeDistance"] intValue];
    [ScreenEyeDistance_outlet setTitle:[NSString stringWithFormat:@"Screen eye distance %dcm",eyeDistance]];
}

- (void) setCombinationRepeatCounterMaxNotification:(NSNotification *)aNotification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (aNotification)
    NSDictionary *dict = [aNotification userInfo];
    NSInteger counter = [[dict objectForKey:@"combinationRepeatCounterMax"] intValue];
    [self setCombinationRepeatCounterMax:counter];
}




- (void) timerOsciHandler: (NSTimer *) timer {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (timer)
	[self indicateRecording: gEpState == epStateRecording];
	NSMutableArray *voltages = [NSMutableArray arrayWithCapacity: 8];
	for (NSUInteger iChannel = 0; iChannel < gNumberOfChannels; ++iChannel)
		[voltages addObject: [NSNumber numberWithFloat: [Interrupt1kHz voltageAtChannel: iChannel]]];
	if (!isInCriticalSection) [osci advanceWithSamples: voltages];
	//	[osci advanceWithSamples: voltages];
}


////////////////////////////////////////////////////////////////////////////////////
- (void) awakeFromNib {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	[operatorWindow setBackgroundColor: [NSColor colorWithDeviceWhite: (CGFloat)0.25 alpha: 1]];
	[operatorWindow setTitle: [NSString stringWithFormat: @"EP2010  (vs %s)", kCurrentVersionDate]];
	[operatorWindow setFrameTopLeftPoint: NSMakePoint(0, CGDisplayPixelsHigh([SetupInfo displayID4operator])-22)];
	
	popupEyes = [NSArray arrayWithObjects: popupEye00_outlet, popupEye01_outlet, popupEye02_outlet, popupEye03_outlet, popupEye04_outlet, nil];
	for (NSPopUpButton *aButton in popupEyes) {
		[aButton removeAllItems];
        for (NSUInteger iEye = 0; iEye < [SetupInfo eyeCount]; ++iEye) {
            [aButton addItemWithTitle: [SetupInfo eyeAtIndex:iEye]];
        }
	}
	popupPositions = [NSArray arrayWithObjects: popupPos00_outlet, popupPos01_outlet, popupPos02_outlet, popupPos03_outlet, popupPos04_outlet, nil];
	for (NSPopUpButton *aButton in popupPositions) {
		[aButton removeAllItems];
        for (NSUInteger iPosition = 0; iPosition < [SetupInfo positionCount]; ++iPosition) {
            [aButton addItemWithTitle: [SetupInfo positionAtIndex:iPosition]];
        }
	}
	
	gEpState = epStateIdling;
	//&	oglTargetMain = [[OGLTargetMain alloc] init];	// oglTargetEcho is instantiated by InterfaceBuilder
	if ([SetupInfo numberOfDisplays] > 1) {
		NSRect stimFrame = NSMakeRect(0, 0, [[SetupInfo screen4stimulator] frame].size.width, [[SetupInfo screen4stimulator] frame].size.height);
		//  NSBackingStoreRetained / NSBackingStoreNonretained / NSBackingStoreBuffered
		stimScreenWindow =  [[NSWindow alloc] initWithContentRect:stimFrame styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES screen: [SetupInfo screen4stimulator]];
		oglTargetMain = [[OGLTargetMain alloc] initWithFrame:stimFrame];
		[stimScreenWindow setContentView: oglTargetMain];
		[stimScreenWindow setLevel: NSMainMenuWindowLevel+1];
		[stimScreenWindow setOpaque: YES];
		[stimScreenWindow setHidesOnDeactivate:YES];
		[stimScreenWindow makeKeyAndOrderFront:self];
	}
	
	stimStepper = [[StimulusStepper alloc] init];
	interrupt1kHz = [[Interrupt1kHz alloc] init];
	[osci setFullscale: 0.2*[Interrupt1kHz maxVoltage]];
	
	[stimStepper setDelegate4StimRenderingStimulator: oglTargetMain];  [stimStepper setDelegate4StimRenderingEcho: oglTargetEcho];
	
	camera = [[Camera2 alloc] initWithView: mCaptureView];	//	let's use the camera if found
	
	//	rcAmp = [[RCAmp alloc] init];	[self setAmplifierInputOpenTo: NO];
	_numberOfChannelsMax = 4;
	[popupNumberOfChannels_outlet removeAllItems];
	for (NSUInteger	iChan=0; iChan < _numberOfChannelsMax; ++iChan) [popupNumberOfChannels_outlet addItemWithTitle: [NSString stringWithFormat:@"%i", iChan+1]];
	[self setNumberOfChannels: 2];
	[self setCombinationRepeatCounterMax: 8];  [self setCurrentCombinationRepeatCounter: 0];  [self setCurrentSweep: 0];  [self setCurrentArtifacts: 0];
		
	avTrace = [[Oscilloscope3 alloc] initWithFrame: NSMakeRect(670, 750-400, 340, 400)];  [avTrace setBackgroundColor: NSColor.lightGrayColor];
	[[operatorWindow contentView] addSubview: avTrace];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAverages:) name:@"averagingDoneNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordingDone:) name:@"recordingDoneNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCombinationRepeatCounterNotification:) name:@"setCombinationRepeatCounterNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSequenceCounterNotification:) name:@"setSequenceCounterNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setSweepCounterNotification:) name:@"setSweepCounterNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setArtifactCounterNotification:) name:@"incrementArtifactCountNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNumberOfChannelsNotification:) name:@"setNumberOfChannelsNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setEyeNotification:) name:@"setEyeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setPositionNotification:) name:@"setPositionNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setScreenEyeDistanceNotification:) name:@"setScreenEyeDistanceNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCombinationRepeatCounterMaxNotification:) name:@"setCombinationRepeatCounterMaxNotification" object:nil];
	
	prefsController = [[PrefsController alloc] init];
	[fieldEpNum_outlet setIntegerValue: [prefsController epNumber]+(NSUInteger)1];
	[fieldBlockNum_outlet setStringValue: @"A"];
	
	if ([prefsController unitsPerMicroVolt] < 0.001)  [prefsController setUnitsPerMicroVolt: kDefaultUnitsPerMicroVolt];
	
	[popupSequenceCombination_outlet removeAllItems];
	for (NSUInteger i=0; i < [stimStepper combinationCounterMax]; ++i) {
		[stimStepper selectSequenceCombination: i];
        [popupSequenceCombination_outlet addItemWithTitle: [stimStepper combinationName]];
	}
	[popupSequenceCombination_outlet selectItemAtIndex: 1];
	[[fieldFrameRateInHz_outlet formatter] setMaximumFractionDigits: 2];
	//	NSLog(@"%s exit.", __PRETTY_FUNCTION__);
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {	NSLog(@"%s", __PRETTY_FUNCTION__);	// this is always after "awakeFromNib"
#pragma unused (aNotification)
	timerGCDOsci = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
	dispatch_source_set_timer(timerGCDOsci, dispatch_time(DISPATCH_TIME_NOW, 0), /*interv*/ 30000000ull , /*leeway*/ 0ull);
	dispatch_source_set_event_handler(timerGCDOsci, ^{
		NSMutableArray *voltages = [NSMutableArray arrayWithCapacity: 8];
		for (NSUInteger iChannel = 0; iChannel < gNumberOfChannels; ++iChannel)
			[voltages addObject: [NSNumber numberWithFloat: [Interrupt1kHz voltageAtChannel: iChannel]]];
		if (!isInCriticalSection) [osci advanceWithSamples: voltages];
		[self indicateRecording: gEpState == epStateRecording];
	});
	dispatch_resume(timerGCDOsci);
}


////////////////////////////////////////////////////////////////////////////////////
// some delegate responses
////////////////////////////////////////////////////////////////////////////////////


- (void) applicationWillTerminate:(NSNotification *)notification {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (notification)
	[Interrupt1kHz invalidate];  //[interrupt1kHz release];
	[self setAmplifierInputOpenTo: NO];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	dispatch_suspend(timerGCDOsci);  dispatch_source_cancel(timerGCDOsci);  //dispatch_release(timerGCDOsci); Why can't I release???
	[camera stopAndClose];
	[stimStepper suspendGDCTasks];  //[stimStepper release];
	[osci release];
	//	[oglTargetMain release];
}


- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
#pragma unused (theApplication)
	return YES;
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)theApplication {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (theApplication)
	return YES;
}

- (BOOL) acceptsFirstResponder { return YES; }

////////////////////////////////////////////////////////////////////////////////////



- (void) popupSequenceCombination_action: (id)sender {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused(sender)
	[stimStepper selectSequenceCombination: [popupSequenceCombination_outlet indexOfSelectedItem]];
}

- (void) buttonRecord_action: (id)sender {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused(sender)
	[SweepOperations clearAll];
    
    [self updateAverages: nil];
	[SetupInfo recalculate];
	[SetupInfo setFrameRateInHz: 1.0 / [stimStepper videoRefreshPeriod]];//	NSLog(@"SetupInfo frameRateInHz: %f", [SetupInfo frameRateInHz]);
	[fieldFrameRateInHz_outlet setFloatValue: [SetupInfo frameRateInHz]];
	[self setCurrentCombinationRepeatCounter: 1];  [self setCurrentSweep: 1];
	[oglTargetMain setVSync: [checkboxVSync_outlet state]];
    
	[stimStepper selectSequenceCombination: [popupSequenceCombination_outlet indexOfSelectedItem]];
	[stimStepper sequenceCombinationStart];
}




- (IBAction) buttonInput_action: (id) sender {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused(sender)
	//	[self setAmplifierInputOpenTo: ![rcAmp isOpenChannel0]];
}


- (void) buttonWhat: (id)sender {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused(sender)
	NSLog(@"buttonWhat");
}



////////////////////////////////////////////////////////////////////////////////////
// Saving
////////////////////////////////////////////////////////////////////////////////////
- (void) saveAverages {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSInteger epNum = [fieldEpNum_outlet integerValue];
	NSMutableString *fileString = [NSMutableString stringWithContentsOfFile: [MiscSingletons pathToEPFileGivenEPNum: epNum] encoding:NSMacOSRomanStringEncoding error: NULL];
	if (fileString.length <1) {
		fileString = [NSMutableString stringWithCapacity: 10000]; [fileString appendString: @"IGOR\n"];
	}
	NSUInteger blockNum = [MiscSingletons blockNumberFromChar: [[fieldBlockNum_outlet stringValue] characterAtIndex:0]];//	NSLog(@"saveTraces, block: %d", blockNum);
    
    
    for (NSUInteger iStimageSequence = 0; iStimageSequence < [stimStepper getSequenceCounterMax]; ++iStimageSequence) {
		
        NSMutableArray *waveNameArray = [NSMutableArray arrayWithCapacity: gNumberOfChannels];
        for (NSUInteger iChan=0; iChan < gNumberOfChannels; ++iChan) {
            [waveNameArray addObject: [MiscSingletons composeWaveNameFromBlockNum: blockNum andSequenceNum: iStimageSequence andChannel: iChan]];
        }
        [fileString appendString: @"WAVES /O "];
        for (NSUInteger iChan=0; iChan < gNumberOfChannels; ++iChan) {
            [fileString appendString: [waveNameArray objectAtIndex: iChan]];  [fileString appendString: @" "];
        }
        [fileString appendString: @"\nBEGIN\n"];
        CGFloat scaleFactor = 1.0 / [prefsController unitsPerMicroVolt] / 1E6;
        for (NSUInteger iSample=0; iSample < [Interrupt1kHz samplesPerSweep]; ++iSample) {
            for (NSUInteger iChan=0; iChan < gNumberOfChannels; ++iChan) {
                [fileString appendFormat: @"%.3e\t", gSweepsAveraged[iStimageSequence].sweep[iChan][iSample] * scaleFactor];
            }
            [fileString appendString: @"\n"];
        }
        [fileString appendString: @"END\n"];
        
        for (NSUInteger iChan=0; iChan < gNumberOfChannels; ++iChan) {
            [fileString appendFormat: @"X SetScale /P x %g, %g, \"ms\" %@\n", round(1E3*-1.5*[stimStepper videoRefreshPeriod]), kSampleIntervalInMs, [waveNameArray objectAtIndex: iChan]];
            [fileString appendFormat: @"X SetScale y -1, 1, \"V\" %@\n", [waveNameArray objectAtIndex: iChan]];
        }
        for (NSUInteger iChan=0; iChan < gNumberOfChannels; ++iChan) {
            NSString *ws = [waveNameArray objectAtIndex: iChan];
            [fileString appendFormat: @"X note %@, \"%s:%@;", ws, kKeyVersion, @kCurrentVersionDate];
            [fileString appendFormat: @"%s:%d;", kKeyEPNumber, epNum];
            [fileString appendFormat: @"%s:%d;", kKeyBlockNumber, blockNum];
            [fileString appendFormat: @"%s:%d;", kKeySequenceNumber, iStimageSequence];
            [fileString appendFormat: @"%s:%d;", kKeyChannel, iChan];
            [stimStepper selectStimageNo: 0 inSequenceNo:iStimageSequence];
            [fileString appendFormat: @"%s:%@;", kKeySequenceName, [stimStepper sequenceName]];
            [fileString appendFormat: @"%s:%@;", kKeyCombinationName, [stimStepper combinationName]];
			[fileString appendFormat: @"%s:%@;", kKeyDateRecording, [MiscSingletons date2YYYY_MM_DD: NSDate.date]];
            [fileString appendFormat: @"%s:%@;", kKeyTimeRecording, [MiscSingletons date2HH_MM_SS: NSDate.date]];
            [fileString appendFormat: @"\"\nX note %@, \";", ws];
            [fileString appendFormat: @"%s:%@;", kKeySubjectName, fieldSubjectName.stringValue];
            [fileString appendFormat: @"%s:%@;", kKeyDateBorn, [MiscSingletons date2YYYY_MM_DD: dateFieldBirthDate.dateValue]];
            [fileString appendFormat: @"%s:%@;", kKeySubjectPIZ, fieldSubjectPIZ.stringValue];
            [fileString appendFormat: @"%s:%g;", kKeyAcuityOD, fieldAcuityOD.floatValue];
            [fileString appendFormat: @"%s:%g;\"\n", kKeyAcuityOS, fieldAcuityOS.floatValue];
            
            [fileString appendFormat: @"X note %@, \";%s:%@;", ws, kKeyDoctor, fieldReferrer.stringValue];
            [fileString appendFormat: @"%s:%@;", kKeyDiagnosis, fieldDiagnosis.stringValue];
            [fileString appendFormat: @"%s:%@;\"\n", kKeyRemark, fieldRemark.stringValue];
			
            [fileString appendFormat: @"X note %@, \";%s:%@;", ws, kKeyEyeKey, [stimStepper getEyeForChannel:iChan]];
            // NSLog(@"Eye: %@", [stimStepper getEyeForChannel:iChan]);
            // NSLog(@"Position: %@", [stimStepper getPositionForChannel:iChan]);
            
            [fileString appendFormat: @"%s:%@;", kKeyEPKey,  @"VEP"];
            [fileString appendFormat: @"%s:%@;", kKeyPositionKey,[stimStepper getPositionForChannel:iChan]];
            [fileString appendFormat: @"nSweeps:%d;",[stimStepper getSequenceCounterMax]];
            [fileString appendFormat: @"\"\nX note %@, \";", ws];
            [fileString appendFormat: @"%s:%g;", kKeyDistance, [SetupInfo screenEyeDistanceInCentimeters]];
            
            [stimStepper selectStimageNo: 0 inSequenceNo:iStimageSequence];
            StimageSequence *stimageSequence = [stimStepper selectedStimageSequence];
			
            for (NSUInteger iStimage = 0; iStimage < [stimageSequence stimageCounterMax]; ++iStimage) {
                [stimStepper selectStimageNo: iStimage inSequenceNo:iStimageSequence];
                stimageSequence = [stimStepper selectedStimageSequence];
                [fileString appendFormat: @"%s%d:%@;", kKeyStimageName,iStimage, [stimStepper stimageName]];
                [fileString appendFormat: @"%s%d:%@;", kKeySymmetry,iStimage, (([stimStepper stimageSymmetry]) ? @"true" : @"false")];
                [fileString appendFormat: @"%s%d:%g;", kKeyLuminance,iStimage, [stimStepper stimageLuminance]];
                [fileString appendFormat: @"%s%d:%g;", kKeyContrast,iStimage, [stimStepper stimageContrast]];
                [fileString appendFormat: @"%s%d:%g;", kKeyElemSize,iStimage, [stimStepper stimageElementSizeInDeg]];
                [fileString appendFormat: @"%s%d:%g;", kKeyStimFrequency,iStimage, (1.0/[stimStepper stimageDurationInFrames])];
                [fileString appendFormat: @"%s%d:%d;", kKeyFramesPerImage,iStimage, [stimStepper stimageDurationInFrames]];
            }
            [fileString appendFormat: @"\"\nX note %@, \";", ws];
            [fileString appendFormat: @"\"\n"];
        }
        [fileString appendString: @"\n\n"];
    }
    
	
	NSString *path = [NSString stringWithString: [MiscSingletons pathToEPFileGivenEPNum: epNum]];
	BOOL result = [fileString writeToFile: path atomically: YES encoding: NSMacOSRomanStringEncoding error: NULL];
	if (!result)
		NSRunAlertPanel(@"Alert:", @"Recording could not be written to disk.", @"OK", NULL, NULL);
	[prefsController setEpNumber: [fieldEpNum_outlet integerValue]];
	[prefsController setBlockNumber: [MiscSingletons blockNumberFromChar: [[fieldBlockNum_outlet stringValue] characterAtIndex:0]]];
}

- (void)dealloc {
    [super dealloc];
}

@end
