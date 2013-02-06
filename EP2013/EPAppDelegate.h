//
//  EPAppDelegate.h
//  EP2013
//
//  Created by bach on 13.01.10.
//  Copyright 2010 Prof. Michael Bach. All rights reserved.
//
/*
History
=======

2012-07-25 saveAverages: Added a for-loop to save the sweeps for each stimageSequence
	some changes to store combination names, sequence names, stimage names etc.
2012-07-24 updateAverages shows averaged sweeps for current stimageSequence
2012-07-23 New notifications to update user interface (currentCombinationRepeatCounter,
	currentSequence, combinationRepeatCounterMax, etc.
	popupEyes and popupPositions get their defauls values from SetupInfo.pList file
2012-07-23 currentCombinationRepeatCounter, currentSequence, combinationRepeatCounterMax
	added to interact with modified user interface.
2012-05-15 change from "popupSequence_outlet" to "popupSequenceCombination_outlet"
2012-02-29	added stuff on the eye and position buttons (not saved yet)
2012-02-28	added many saving details
2012-01-03	added averaging indicator
2011-12-27	made "numberOfChannels" global (–> gNumberOfChannels)

 
 

 

*/

#import <Cocoa/Cocoa.h>
#import "StimulusStepper.h"
#import "OGLTargetEcho.h"
#import "OGLTargetMain.h"
#import "Interrupt1kHz.h"
#import "Camera2.h"
#import "Oscilloscope3.h"
#import "SweepOperations.h"
#import "Oscilloscope2OGL.h"


@interface EPAppDelegate : NSObject <NSApplicationDelegate> {
    IBOutlet NSWindow *operatorWindow;
	IBOutlet OGLTargetEcho *oglTargetEcho;
	IBOutlet QTCaptureView	*mCaptureView;	// VideoIn -> View
	IBOutlet Oscilloscope2OGL *osci;
	IBOutlet NSTextField *fieldEpNum_outlet, *fieldBlockNum_outlet, *fieldSubjectName, *fieldSubjectPIZ, *fieldDiagnosis, *fieldRemark, *fieldCombinationRepeatCounter, *fieldFrameRateInHz_outlet, *fieldSequences_outlet;
    IBOutlet NSTextField *fieldSweeps_outlet;
    IBOutlet NSTextField *fieldArtifacts_outlet;
	IBOutlet NSTextFieldCell *fieldAcuityOD, *fieldAcuityOS;
	IBOutlet NSComboBox *fieldReferrer;
	IBOutlet NSDatePicker *dateFieldBirthDate;
	IBOutlet NSPopUpButton *popupNumberOfChannels_outlet;
	IBOutlet NSPopUpButton *popupEye00_outlet, *popupEye01_outlet, *popupEye02_outlet, *popupEye03_outlet, *popupEye04_outlet;
	IBOutlet NSPopUpButton *popupPos00_outlet, *popupPos01_outlet, *popupPos02_outlet, *popupPos03_outlet, *popupPos04_outlet;
	IBOutlet NSBox *boxIndicator1_outlet;
	IBOutlet NSPopUpButton *popupSequenceCombination_outlet;
	IBOutlet NSButton *buttonInput_outlet, *checkboxVSync_outlet;
	NSUInteger combinationRepeatCounterMax, currentArtifacts;
    NSInteger currentSequence,currentCombinationRepeatCounter,currentSweep;
    IBOutlet NSTextFieldCell *ScreenEyeDistance_outlet;
}


- (IBAction) popupNumberOfChannels_action: (id) sender;
- (IBAction) combinationRepeatCounterMax_action: (id) sender;
- (IBAction) popupSequenceCombination_action: (id) sender;
- (IBAction) buttonRecord_action: (id) sender;
- (IBAction) buttonInput_action: (id) sender;
- (IBAction) buttonWhat: (id) sender;

@property (assign) IBOutlet NSWindow *operatorWindow;

@property (readwrite) NSUInteger numberOfChannels;

@property (readwrite) NSInteger currentCombinationRepeatCounter;
@property (readwrite) NSInteger currentSequence;
@property (readwrite) NSInteger currentSweep;
@property (readwrite) NSUInteger currentArtifacts;
@property (readwrite) NSUInteger combinationRepeatCounterMax;

- (void) saveAverages;
- (void) setNumberOfChannels: (NSUInteger) channels;


@end
