//
//  SweepOperations.h
//  EP2010
//
//  2012-07-24 Added "forStimageSequence" to "averageFromBufferNumber". The last raw data is averaged to the correct sweep.
//  Created by bach on 10.02.12.
//  Copyright 2012 Department of Ophthalmology, University Medical Center Freiburg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Globals.h"
#import "Interrupt1kHz.h"


@interface SweepOperations : NSObject {
@private
    
}


+ (void) clearAll;
+ (void) averageFromBufferNumber: (NSUInteger) bufferNumber forStimageSequence: (NSUInteger) iSequence;

	
@end
