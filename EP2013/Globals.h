/*
Globals.h
EP2010

Copyright 2009–2012 Prof. Michael Bach. All rights reserved.
 
 
History
=======


2012-07-26  Changed kMaxSequenceCounterRepeats to kSequenceCounterMax (to unify nomenclature)
2012-02-24  removed RCAmp – it worked, but let's make deployment as easy as possible (a-09)
2012-02-15	fixed errors in saving, fine-tuning for correct time recording
2012-02-14	GREAT MOMENT! Recorded first VEP!
2012-02-13	added simplified sequence selection
2012-02-10	CoreVideoDisplayLink didn't synchronise. CGBeamposition is out in Lion. Synchronisation issue was coupled with the oscilloscope.
			Analog acquisition now correctly controlled. Created SweepOperations to remove averaging from main controler.
2012-01-16	"Saving" module back-integrated to the main delegate
2012-01-10	Saving works, added PrefsController, integrated ScreenInfo into SetupInfo
2011-12-29	recorded from an on-screen photocell for the first time -- doesn't seem to jitter, but lots of open questions
2011-11-22	moved all variables → @implementation when not used as property (legacy runtime when not using 64-bit model, otherwise could drop the latter declarations)
2011-10-25	DisplayLink geht
2010-01-16	mehrkanaliger Oszi läuft in GCD
2010-01-13	GCD läuft mit 1 kHz-Timer & Reizdarstellung
2009-09-09	begonnnen mit einem OpenGL-Schachbrett
 
 */


#define kCurrentVersionDate "2012-07-25"

#define max(x,y) ((x) > (y)) ? (x) : (y)	
#define min(x,y) ((x) > (y)) ? (y) : (x)


#define kSampleIntervalInMs 1.0
#define kDefaultUnitsPerMicroVolt 0.00475

#define kSequenceCounterMax	8
// #define kMaxRepetitionsPerStimulus 26            // No longer needed? TM 2012-07-26
#define kNumPointsOscilloscope	1000
#define kMaxNumberOfChannels	5	// this must be larger or equal to the number of channels the amplifier is capable of
#define kMaxSamples				3001
#define kMaxSweeps				250

////////////////////////////////////////////////////////////////////////////////////
// Structure describing data acquired per channel
typedef struct  {
	CGFloat sweep[kMaxNumberOfChannels][kMaxSamples];
	CGFloat coeffSin[kMaxNumberOfChannels][kMaxSweeps], coeffCos[kMaxNumberOfChannels][kMaxSweeps];
	NSUInteger samplesPerSweep;
	NSUInteger nAverages;
	NSUInteger nArtifacts;
	BOOL isArtifact;
} sweepStruct, *sweepStructPtr, **sweepStructHdl;
sweepStruct gSweepsRaw[2], gSweepsAveraged[kSequenceCounterMax];


#define kKeyTopLeftHasForeColor "topLeftHasForeColor"
//";eyeKey:OS;epKey:ERG;nSweeps:40;nArtefs:15;seqName:Checks trans 0.8/15°;
//frequency:1.70;onTime1:293.35;;samplesPerFrame:13.334;

enum EPStates {epStateIdling=0, epStateRecording, epStatePausedSweep, epStateNeedsSweepStart, epStateInSweep, epStateDoneSweep, epStateHandlingSweep};
NSUInteger gEpState;


NSUInteger gNumberOfChannels;
BOOL isInCriticalSection;

enum StimagePatternID {homogenous=0, checkerboard, gratingSquare, gratingSine, scene};


