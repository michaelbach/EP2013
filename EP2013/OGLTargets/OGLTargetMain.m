//
//  OGLTargetMain.m
//  StimulatorSimulator
//
//  Created by bach on 18.09.09.
//  Copyright 2009 Universitäts-Augenklinik. All rights reserved.
//

#import "OGLTargetMain.h"
#import "AbsoluteTimeUtils.h"
#import "SetupInfo.h"


@implementation OGLTargetMain


static bool displayAvailable;
static NSOpenGLContext *oglContext;
static NSRect targetRect;
static id storedStimImage;
static NSOpenGLPixelFormat *pixelFormat;


@synthesize vSync;


- (id)initWithFrame:(NSRect)frameRect {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	displayAvailable = NO;
    self = [super initWithFrame:frameRect];
    if (self) {
		if ([SetupInfo numberOfDisplays] < 2) return self;
		storedStimImage = NULL;
		targetRect = frameRect;
		oglContext = nil;
		// NSOpenGLPFADoubleBuffer / NSOpenGLPFAPixelBuffer
        NSOpenGLPixelFormatAttribute attrs[] = {NSOpenGLPFAAccelerated, NSOpenGLPFADoubleBuffer, NSOpenGLPFAColorSize, 32, 0};
		pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes: attrs];
		if (pixelFormat == nil) {
			NSLog(@"“initWithAttributes” failed");  return Nil;
		}
		displayAvailable = YES;
		vSync = YES;
	}
	return self;
}


- (void) prepareOpenGL {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	storedStimImage = NULL;
	glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
	glLoadIdentity();
    glOrtho(-(GLdouble)([SetupInfo screenWidthInPixels]/2), [SetupInfo screenWidthInPixels]/2, -(GLdouble)([SetupInfo screenHeightInPixels]/2), [SetupInfo screenHeightInPixels]/2, -1.0, 1.0);
	// (when) drawing 2D images, disable all irrelevant state variables …
	glDisable(GL_DITHER);  glDisable(GL_ALPHA_TEST);  glDisable(GL_BLEND);  glDisable(GL_STENCIL_TEST);
	glDisable(GL_FOG);  glDisable(GL_TEXTURE_2D);  glDisable(GL_DEPTH_TEST);  glPixelZoom(1.0,1.0);
}


- (NSOpenGLContext*) openGLContext {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	if(!oglContext) {
		oglContext = [[NSOpenGLContext alloc] initWithFormat: pixelFormat shareContext:nil];
		if(!oglContext) NSLog(@"Fehler beim Anlegen des OpenGL Context");
	}
	return (oglContext);
}


// dies wird vor drawRect automatisch aufgerufen
-(void) lockFocus {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	NSOpenGLContext* c = [self openGLContext];
	[super lockFocus];
	if([c view] != self)  [c setView:self];
	[c makeCurrentContext];
}


- (void) oglTarget_drawWithImage: (id) stimImage {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	storedStimImage = stimImage;	[self setNeedsDisplay: YES];
}


- (void)drawRect:(NSRect)rect {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
#pragma unused (rect)
	GLint newSwapInterval = vSync ? 1 : 0;  [oglContext setValues: &newSwapInterval forParameter: NSOpenGLCPSwapInterval];
	//	AbsoluteTimeUtils *t = [[AbsoluteTimeUtils alloc] init];
	if (!displayAvailable) return;
	isInCriticalSection = YES;	// das brauchen wir wahrscheinlich nicht
	[oglContext update];	// juhu, mit diesem "update" sind jetzt die Fehler weg die bei der CVDisplayLink auftraten!!
	CGLLockContext([oglContext CGLContextObj]);// must lock GL context because display link is threaded
	if (storedStimImage != NULL)
		[storedStimImage drawRect: targetRect];
	else {	// entry screen
		glClearColor(0.3, 0.3, 0.5, 0);  glClear(GL_COLOR_BUFFER_BIT);
		NSDictionary* standStringAttrib = [NSDictionary dictionaryWithObjectsAndKeys: [NSFont fontWithName:@"Helvetica" size:48], NSFontAttributeName, [NSColor blackColor], NSForegroundColorAttributeName, nil];
		GLString *theString=[[GLString alloc] initWithString:[NSString stringWithFormat:@"  EP2013  "] withAttributes:standStringAttrib withTextColor:[NSColor blackColor] withBoxColor:[NSColor greenColor] withBorderColor:[NSColor yellowColor]];
		GLfloat f = 100;
		[theString drawWithBounds: NSMakeRect(-f, f, 2*f, -f)];
		[theString release];

	}
	[oglContext flushBuffer];
	CGLUnlockContext([oglContext CGLContextObj]);
	isInCriticalSection = NO;
	//	[t logMilliseconds];
}


- (BOOL)isOpaque {return YES;}


- (void) dealloc {	 NSLog(@"%s", __PRETTY_FUNCTION__);
	[oglContext release];
	[super dealloc];
}


@end
