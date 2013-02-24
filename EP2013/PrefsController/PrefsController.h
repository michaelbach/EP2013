//
//  PrefsController.h
//
//  Created by bach on 2012-01-10.
//  Copyright 2012 Universitäts-Augenklinik. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Globals.h"


@interface PrefsController : NSUserDefaultsController



@property CGFloat unitsPerMicroVolt;
@property NSUInteger epNumber;
@property NSUInteger blockNumber;


@end
