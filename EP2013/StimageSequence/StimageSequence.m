//
//  StimageSequence.m
//  EP2013
//
//  Created by Thomas Meigen on 23.07.12.
//  Copyright (c) 2012 Univ.-Augenklinik Würzburg. All rights reserved.
//

#import "StimageSequence.h"



@implementation StimageSequence

static NSMutableArray* stimageArray;


@synthesize sequenceName, sequenceDetails, stimageCounterMax, sequenceRepeatCounterPre,sequenceRepeatCounterMax;




- (void) addStimage: (Stimage*) theStimage{
    [stimageArray addObject:theStimage];
}

- (NSUInteger) getStimageCounterMax {
    return [stimageArray count];
}

- (Stimage*) stimageAtIndex:(NSUInteger) index {
    return [stimageArray objectAtIndex:index];
}




- (id)init {
    self = [super init];
    if (self) {
        stimageArray = [[NSMutableArray arrayWithCapacity: 2] retain];
        
        // Setting some default values for Counter and CouterMax variables
        stimageCounterMax = 2;
        
        sequenceRepeatCounterPre = 1;
        sequenceRepeatCounterMax = 10;
     }
    return self;
}


- (void)dealloc {
    [super dealloc];
}



@end
