//
//  Interrupt1kHz.m
//
//
//	2011-10-24	converted to using displayLink, so we don't need to call the StimulusStepper from here
//
//  Created by bach on 15.09.09.
//  Copyright 2009 Universitäts-Augenklinik. All rights reserved.
//

#import "Interrupt1kHz.h"


@implementation Interrupt1kHz


static NSUInteger currentBuffer;
static NSInteger sampleIndex, samplesPerSweep;
static BOOL isInInterrupt = NO;
static CGFloat allAnalogChannels[kMaxNumberOfChannels];
static NIDAQX *processIO;
static dispatch_source_t timer1kHzGCD;
static AbsoluteTimeUtils *absTime;


//	"initialize" is only sent once to each class
+ (void)initialize {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	if (self == [Interrupt1kHz class]) {}
}


+ (void) setSampleIndex: (NSInteger) value {
	while (isInInterrupt);	// hopefully: 1. this is not optimised away, 2. this will not be endless…
	sampleIndex = value;
}


+ (void) setSamplesPerSweep: (NSUInteger) value {	//	NSLog(@"Interrupt1kHz>setSamplesPerSweep %u", samplesPerSweep);
	samplesPerSweep = value;
}


+ (NSUInteger) samplesPerSweep {
	return samplesPerSweep;
}


+ (void) setNumberOfArtifacts: (NSUInteger) value {
	while (isInInterrupt);	// hopefully: 1. this is not optimised away, 2. this will not be endless…
	gSweepsRaw[currentBuffer].nArtifacts = value;
}
+ (void) numberOfArtifactsReset {
	while (isInInterrupt);	// hopefully: 1. this is not optimised away, 2. this will not be endless…
	gSweepsRaw[currentBuffer].nArtifacts = 0;
}
+ (void) setArtifact {
	gSweepsRaw[currentBuffer].isArtifact = true;
}


+ (void) setBufferNumber: (NSUInteger) value {
	currentBuffer = value;
}
+ (NSUInteger) bufferNumber {
	return 	currentBuffer;
}
+ (void) bufferToggle {
	currentBuffer = currentBuffer ? 0 : 1;
}


+ (void) handle1kHzTimerGCD {
	isInInterrupt = YES;
	if (++sampleIndex >= kMaxSamples) sampleIndex = kMaxSamples-1;
	if (gEpState == epStateRecording) {
		if (sampleIndex > samplesPerSweep) samplesPerSweep = sampleIndex;
	}
	for (NSUInteger iChannel = 0; iChannel < gNumberOfChannels; ++iChannel) { // grab the analog voltages
		CGFloat v = [processIO voltageAtChannel: iChannel];
		//if (iChannel == 0) v = 0.000001f*[absTime elapsedMilliseconds];	// we don't record channel 0, but use it for time
		//if (iChannel == 2) v = 0.0001f*sampleIndex;
        v = v * 0.05;	// dieser Wert brachte mit vorhandener Verstärkung dieselbe Auslenkung wie früher im Oszi
		allAnalogChannels[iChannel] = v;
		gSweepsRaw[currentBuffer].sweep[iChannel][sampleIndex] = v;	 //NSLog(@"%f", v);
	}
	isInInterrupt = NO;
}


+ (CGFloat) voltageAtChannel: (NSUInteger) channel {
	if (channel >= gNumberOfChannels) return 0;
	return allAnalogChannels[channel];
}
+ (CGFloat) maxVoltage {
	return [processIO maxVoltage];
}


+ (void) invalidate {
	if (timer1kHzGCD) dispatch_suspend(timer1kHzGCD);
//	if (timer1kHzGCD) dispatch_release(timer1kHzGCD);
	[processIO invalidate];
}


-(id) init {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	if ((self = [super init])) {
		[Interrupt1kHz setBufferNumber: 0];  [Interrupt1kHz setSampleIndex: 0];  [Interrupt1kHz setNumberOfArtifacts: 0]; [Interrupt1kHz setSamplesPerSweep: 0];
	
		absTime = [[AbsoluteTimeUtils alloc] init];
	
		processIO = [[NIDAQX alloc] init];  //NSLog(@"%s, [[NIDAQX alloc] init] ok.", __PRETTY_FUNCTION__);
		
		timer1kHzGCD = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
		dispatch_source_set_timer(timer1kHzGCD, dispatch_time(DISPATCH_TIME_NOW, 0), /*interv*/ 1ull * USEC_PER_SEC, /*leeway*/ 0ull);
		dispatch_source_set_event_handler(timer1kHzGCD, ^{ [Interrupt1kHz handle1kHzTimerGCD]; }); 
		dispatch_resume(timer1kHzGCD);
	}
	return self;
}


- (void) dealloc {	 //	NSLog(@"%s", __PRETTY_FUNCTION__);
	[Interrupt1kHz invalidate];
	[processIO release];
	[absTime release];
	[super dealloc];
}


@end
