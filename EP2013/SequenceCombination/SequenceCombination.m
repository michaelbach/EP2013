//
//  SequenceCombination.m
//  EP2013
//
//  Created by Thomas Meigen on 24.07.12.
//  Copyright (c) 2012 Univ.-Augenklinik Würzburg. All rights reserved.
//

#import "StimageSequence.h"
#import "SequenceCombination.h"



@implementation SequenceCombination

static NSMutableArray* eyeArray;
static NSMutableArray* positionArray;
static NSMutableArray* sequenceArray;


@synthesize combinationName, sequenceCounterMax,combinationRepeatCounterMax, channelCounterMax;


- (void) addEye:(NSString *) sEye {
    [eyeArray  addObject:sEye];
    channelCounterMax = [eyeArray count];
}

- (NSString*) getEyeForChannel:(NSUInteger) iChannel {
    return [eyeArray  objectAtIndex: iChannel];
}

- (void) addPosition:(NSString *) sPosition {
    [positionArray  addObject:sPosition];
}

- (NSString*) getPositionForChannel:(NSUInteger) iChannel {
    return [positionArray  objectAtIndex: iChannel];
}



- (void) addSequence: (StimageSequence*) theSequence{
    [sequenceArray addObject:theSequence];
}


- (StimageSequence*) sequenceAtIndex:(NSUInteger) index {
    return [sequenceArray objectAtIndex:index];
}



- (id)init {
    self = [super init];
    if (self) {
        sequenceArray = [[NSMutableArray arrayWithCapacity: 10] retain];
        eyeArray = [[NSMutableArray arrayWithCapacity: 4] retain];
        positionArray = [[NSMutableArray arrayWithCapacity: 4] retain];
        
        
        // Setting some default values for Counter and CouterMax variables
        sequenceCounterMax = 10;
        
        combinationRepeatCounterMax = 10;
    }
    return self;
}


- (void)dealloc {
    [super dealloc];
}




@end
