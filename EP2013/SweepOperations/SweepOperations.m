//
//  SweepOperations.m
//  EP2013
//
//  2012-07-24 Added "forStimageSequence" to "averageFromBufferNumber". The last raw data 
//              is averaged to the correct sweep.
//              Correction of some names (sequenceCounter...)
//  Created by bach on 10.02.12.
//  Copyright 2012 Department of Ophthalmology, University Medical Center Freiburg. All rights reserved.
//

#import "SweepOperations.h"


@implementation SweepOperations





+ (void) clearAll {
	for (NSUInteger sequenceCounter = 0; sequenceCounter < kSequenceCounterMax; ++sequenceCounter) {// clear averages
		for (NSUInteger iChannel = 0; iChannel < gNumberOfChannels; ++iChannel) {
			for (NSUInteger sampleIndex = 0; sampleIndex<kMaxSamples; ++sampleIndex) {
				gSweepsAveraged[sequenceCounter].sweep[iChannel][sampleIndex] = 0.0f;
				gSweepsRaw[0].sweep[iChannel][sampleIndex] = 0.0f;
				gSweepsRaw[1].sweep[iChannel][sampleIndex] = 0.0f;
			}
		}
		gSweepsAveraged[sequenceCounter].nAverages = 0;
		gSweepsAveraged[sequenceCounter].nArtifacts = 0;
		gSweepsAveraged[sequenceCounter].isArtifact = NO;
		gSweepsAveraged[sequenceCounter].samplesPerSweep = 0;
	}
}


+ (void) averageBufferNumber: (NSUInteger) bufferNumber forStimageSequence: (NSUInteger) iSequence {
	//[absTime reset];
	for (NSUInteger iChannel = 0; iChannel < gNumberOfChannels; ++iChannel) {
		for (NSUInteger sampleIndex = 0; sampleIndex<[Interrupt1kHz samplesPerSweep]; ++sampleIndex) {	// averaging
			gSweepsAveraged[iSequence].sweep[iChannel][sampleIndex] += gSweepsRaw[bufferNumber].sweep[iChannel][sampleIndex];
		}
		CGFloat av = 0.0f;
		for (NSUInteger sampleIndex = 0; sampleIndex<20; ++sampleIndex) {	// mean across first 20 ms → baseline
			av += gSweepsAveraged[iSequence].sweep[iChannel][sampleIndex];
		}
		av /= 20.0f;
		for (NSUInteger sampleIndex = 0; sampleIndex<[Interrupt1kHz samplesPerSweep]; ++sampleIndex) {	// set baseline to zero
			gSweepsAveraged[iSequence].sweep[iChannel][sampleIndex] -= av;
		}
	}
	gSweepsAveraged[iSequence].nArtifacts += gSweepsRaw[bufferNumber].nArtifacts;
	gSweepsAveraged[iSequence].nAverages += 1;
	//[absTime logMilliseconds];	// 5 channels, 2001 points: <0.1 ms 2011-12-28
}


- (id)init {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {}
    return self;
}


- (void)dealloc {
    [super dealloc];
}

@end
