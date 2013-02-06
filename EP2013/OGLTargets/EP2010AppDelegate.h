//
//  EP2010AppDelegate.h
//  EP2010
//
//  Created by bach on 13.01.10.
//  Copyright 2010 Prof. Michael Bach. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StimulusStepper.h"
#import "OGLTargetEcho.h"
#import "OGLTargetMain.h"
#import "Interrupt1kHz.h"
#import "Camera2.h"
#import "Oscilloscope2.h"
#import "DisplayInfo.h"


@interface EP2010AppDelegate : NSObject <NSApplicationDelegate> {
	Camera2* camera;
	Interrupt1kHz *interrupt1kHz;
	StimulusStepper *stimStepper;
	OGLTargetMain *oglTargetMain;
	dispatch_source_t timerGCDOsci;
	NSUInteger numberOfChannels, numberOfCycles;
    NSWindow *window;
	IBOutlet OGLTargetEcho *oglTargetEcho;
	IBOutlet QTCaptureView	*mCaptureView;	// VideoIn -> View
	IBOutlet Oscilloscope2 *osci;
	IBOutlet NSPopUpButton *popupNumberOfChannels_outlet, *popupNumberOfCycles_outlet;
	Oscilloscope2 *avTrace;
}

- (IBAction) popupNumberOfChannels_action: (id) sender;
- (IBAction) popupNumberOfCycles_action: (id) sender;
- (IBAction) buttonRecord: (id) sender;
- (IBAction) buttonWhat: (id) sender;

@property (assign) IBOutlet NSWindow *window;
- (NSUInteger) numberOfChannels;
- (void) setNumberOfChannels: (NSUInteger) channels;

- (NSUInteger) numberOfCycles;
- (void) setNumberOfCycles: (NSUInteger) cycles;

@end
