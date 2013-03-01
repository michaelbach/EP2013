//
//  OGLTargetEcho.h
//  StimulatorSimulator
//
//  Created by bach on 18.09.09.
//  Copyright 2009 Prof. Michael Bach. All rights reserved.
//
//	History
//	=======
//
//

#import <Cocoa/Cocoa.h>
#import "Globals.h"
#import "GLString.h"


@interface OGLTargetEcho : NSOpenGLView


- (void) oglTarget_drawWithImage: (id) stimage;


@end
