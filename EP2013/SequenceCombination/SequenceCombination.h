//
//  SequenceCombination.h
//  EP2013
//
//  Created by Thomas Meigen on 24.07.12.
//  Copyright (c) 2012 Univ.-Augenklinik Würzburg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StimageSequence.h"

@interface SequenceCombination : NSObject {
    NSString* combinationName;
    NSUInteger sequenceCounterMax;
	NSUInteger combinationRepeatCounterMax;
    NSUInteger channelCounterMax;
 
}



@property (retain) NSString *combinationName;

@property (assign) NSUInteger sequenceCounterMax;

@property (assign) NSUInteger combinationRepeatCounterMax;

@property (assign) NSUInteger channelCounterMax;


- (void) addEye:(NSString *) sEye;
- (NSString*) getEyeForChannel:(NSUInteger) iChannel;
- (void) addPosition:(NSString *) sPosition;
- (NSString*) getPositionForChannel:(NSUInteger) iChannel;
- (void) addSequence: (StimageSequence*) theSequence;
- (StimageSequence*) sequenceAtIndex:(NSUInteger) index;


@end
