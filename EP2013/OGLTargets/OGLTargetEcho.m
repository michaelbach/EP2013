//
//  OGLTargetEcho.m
//  StimulatorSimulator
//
//  Created by bach on 18.09.09.
//  Copyright 2009 Universitäts-Augenklinik. All rights reserved.
//

#import "OGLTargetEcho.h"	
#import "AbsoluteTimeUtils.h"



@implementation OGLTargetEcho


static CGLContextObj cglContext;
static NSRect targetRect;
static id storedStimImage;


- (void) awakeFromNib {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
}


- (void) prepareOpenGL{	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	storedStimImage = NULL;
	cglContext = [[NSOpenGLContext currentContext] CGLContextObj];
	targetRect = [self frame];  
	// VBL-sync? 1: yes, 0: no
	GLint newSwapInterval = 0;  CGLSetParameter(cglContext, kCGLCPSwapInterval, &newSwapInterval);
	
	// (when) drawing 2D images, disable all irrelevant state variables …
	//	glDisable(GL_DITHER);  glDisable(GL_ALPHA_TEST);  glDisable(GL_BLEND);	glDisable(GL_STENCIL_TEST);  glDisable(GL_FOG);  // <–– lösen alle Absturz aus
	glDisable(GL_TEXTURE_2D);  
	glDisable(GL_DEPTH_TEST);  
	glPixelZoom(1.0,1.0);
}


- (BOOL)isOpaque {return YES;}


- (void) oglTarget_drawWithImage: (id) stimImage {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	storedStimImage = stimImage;  [self setNeedsDisplay: YES];
}



- (void)drawRect:(NSRect)rect {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (rect)
//	AbsoluteTimeUtils *t = [[AbsoluteTimeUtils alloc] init];
	CGLLockContext(cglContext);// must lock GL context because display link is threaded
	if (storedStimImage != NULL)  [storedStimImage drawRect: rect];
	else {	// neutral
		glClearColor(0.3, 0.3, 0.5, 0);  glClear(GL_COLOR_BUFFER_BIT);
	}
	glFlush();
	CGLUnlockContext(cglContext);
//	[t logMilliseconds];
}

@end
