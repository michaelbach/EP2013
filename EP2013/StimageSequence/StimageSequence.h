//
//  StimageSequence.h
//  EP2013
//
//  Created by Thomas Meigen on 23.07.12.
//  Copyright (c) 2012 Univ.-Augenklinik Würzburg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Stimage.h"

@interface StimageSequence : NSObject {
    NSString* sequenceName;
    NSString* sequenceDetails;

    NSUInteger stimageCounterMax;

	NSUInteger sequenceRepeatCounterPre;
	NSUInteger sequenceRepeatCounterMax;
}

@property (retain) NSString *sequenceName;
@property (retain) NSString *sequenceDetails;

@property (assign) NSUInteger stimageCounterMax;

@property (assign) NSUInteger sequenceRepeatCounterPre;
@property (assign) NSUInteger sequenceRepeatCounterMax;

- (void) addStimage: (Stimage*) theStimage;
- (NSUInteger) getStimageCounterMax;
- (Stimage*) stimageAtIndex:(NSUInteger) index;

@end
