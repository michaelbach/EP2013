//
//  OGLTargetMain.h
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


@interface OGLTargetMain : NSOpenGLView {
	BOOL vSync;
}


- (void) oglTarget_drawWithImage: (id) stimImage;
@property (assign) BOOL vSync;

@end
