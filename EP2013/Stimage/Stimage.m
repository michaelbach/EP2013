//
//  Image4Stim.m
//  EP2013
//
//  Created by bach on 2011-10-31.
//  Copyright 2011 Universitäts-Augenklinik. All rights reserved.
//

#import "Stimage.h"


@implementation Stimage


static GLfloat foreColorR, foreColorG, foreColorB, backColorR, backColorG, backColorB;
static CGFloat screenWidthInPixels, screenHeightInPixels;
static GLfloat screenWidthInDegrees, screenHeigtInDegrees, screenLeftInDegrees, screenRightInDegrees, screenBottomInDegrees, screenTopInDegrees;


///////////////////////////////////////
// setting up the stimulus image
///////////////////////////////////////
@synthesize stimagePatternName, stimagePatternID, contrast, luminance, elementSizeInDeg, symmetry, topLeftHasForeColor, frameCounter4StimageMax;





///////////////////////////////////////
// drawing the stimulus image
///////////////////////////////////////


// calculate checksize from dominant frequency | static double CPD2Checksize(const double cpd) {return 1.0/sqrt(2.0)/cpd;}
// calculate dominant frequency from checksize | static double Checksize2CPD(const double deg) {return 1.0/sqrt(2.0)/deg; }
- (void) setForeBackColors {	//	NSLog(@"%f", self.luminance);
	GLfloat normalisedLumi = self.luminance / SetupInfo.maxLuminance;
	GLfloat fore = normalisedLumi * (1 + self.contrast), back = normalisedLumi * (1 - self.contrast);
	foreColorR = fore; foreColorG = fore;  foreColorB = fore;
	backColorR = back; backColorG = back; backColorB = back;
}


- (void) calculateDimensions {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	//	NSLog(@"screenWidthInPixels: %f, screenHeightInPixels: %f", screenWidthInPixels, screenHeightInPixels);
	screenWidthInDegrees = [SetupInfo screenWidthInDegrees];  screenHeigtInDegrees = [SetupInfo screenHeightInDegrees];
	screenRightInDegrees = [SetupInfo screenRightInDegrees]; screenLeftInDegrees = [SetupInfo screenLeftInDegrees];
	screenTopInDegrees = [SetupInfo screenTopInDegrees]; screenBottomInDegrees = [SetupInfo screenBottomInDegrees];
	//	NSLog(@"screenWidthInDegrees: %f, screenHeigtInDegrees: %f", screenWidthInDegrees, screenHeigtInDegrees);
}


- (void) drawRectAtX: (GLfloat) x andY: (GLfloat) y withWidth:  (GLfloat) w andHeight:  (GLfloat) h {
	glBegin(GL_QUADS); {
		glVertex2f(x, y);  glVertex2f(x+w, y);  glVertex2f(x+w, y+h);  glVertex2f(x, y+h);
	} glEnd();
}


- (void) drawSquareAtX: (GLfloat) x Y: (GLfloat) y size:  (GLfloat) s {	// glRect!!!
	GLfloat xs = x+s, ys = y+s;
	glBegin(GL_QUADS); {
		glVertex2f(x, y);  glVertex2f(xs, y);  glVertex2f(xs, ys);  glVertex2f(x, ys);
	} glEnd();
}


- (void) drawFixCrossAtX: (GLfloat) x Y: (GLfloat) y size:  (GLfloat) s {
	GLfloat s2 = s/2.0, x0 = x-s2, x1 = x+s2, y00 = y-s2, y11 = y+s2;
	GLfloat w = [SetupInfo degrees2Pixels: s / 5.0];
	glLineWidth(w < 1.0 ? 1.0 : w);  glColor3f(0.5, 0.5, 0.5);
	glBegin(GL_LINES); {
		glVertex2f(x0, y00);  glVertex2f(x1, y11);  glVertex2f(x1, y00);  glVertex2f(x0, y11);
	} glEnd();
	glLineWidth(1.0);  glColor3f(1, 1, 1);
	glBegin(GL_LINES); {
		glVertex2f(x0, y00);  glVertex2f(x1, y11);  glVertex2f(x1, y00);  glVertex2f(x0, y11);
	} glEnd();
	glColor3f(0, 0, 0);  glPointSize(2);
	glBegin(GL_POINTS); glVertex2f(x, y); glEnd();
}


// n must be ≤ 10
- (void) drawBasicPatternNxN: (NSUInteger) n {//NSLog(@"%s", __PRETTY_FUNCTION__);
	glClearColor(backColorR, backColorG, backColorB, 0);  glClear(GL_COLOR_BUFFER_BIT);
	glColor3f(foreColorR, foreColorG, foreColorB);
	
	glLineWidth(n);  glEnable(GL_LINE_STIPPLE);  
	GLfloat yInc = [SetupInfo pixels2Degrees:n], xLeft = -screenWidthInDegrees/2, xRight = xLeft + screenWidthInDegrees;
	NSUInteger oddCounter=0;
	GLfloat screenHeightHalf = screenHeigtInDegrees/2;
	for (GLfloat y = -screenHeightHalf; y < screenHeightHalf; y += yInc) {
		glLineStipple(n, (topLeftHasForeColor ^ (++oddCounter & 0x01))? 0x5555 : 0xAAAA);
		glBegin(GL_LINES);  glVertex2f(xLeft, y);  glVertex2f(xRight, y);  glEnd();
	}
	glDisable(GL_LINE_STIPPLE);
}


- (void) drawBasicHomogenous { //NSLog(@"%s", __PRETTY_FUNCTION__);
	stimagePatternName = @"homogenous";
	[self setForeBackColors];
	if (topLeftHasForeColor) {
		glClearColor(foreColorR, foreColorG, foreColorB, 0);
	} else {
		glClearColor(backColorR, backColorG, backColorB, 0);
	}
	glClear(GL_COLOR_BUFFER_BIT);
}



- (void) drawBasicCheckerboard { //NSLog(@"%s", __PRETTY_FUNCTION__);
	//	AbsoluteTimeUtils *t = [[AbsoluteTimeUtils alloc] init];
	stimagePatternName = @"checkerboard";
	GLfloat checkSize = elementSizeInDeg;
	CGFloat f = [SetupInfo degrees2Pixels:checkSize];
	if (f < 10) {
		[self drawBasicPatternNxN: f];
	} else {
		glClearColor(backColorR, backColorG, backColorB, 0);  glClear(GL_COLOR_BUFFER_BIT);
		glColor3f(foreColorR, foreColorG, foreColorB);
		NSUInteger xKaros = screenWidthInDegrees / checkSize + 1, yKaros = screenHeigtInDegrees / checkSize + 1, xKaros2 = xKaros/2;
		NSUInteger yCounter = 0;
		for (GLfloat y= -checkSize*(yKaros+1); y < screenTopInDegrees; y+=checkSize) {
			NSUInteger xCounter = 0;
			bool yCriterion = topLeftHasForeColor ^ (++yCounter & 1);	//(bool) Odd(i) {return (i & 1);}
			for (GLfloat x= -checkSize*(xKaros2+1); x < screenRightInDegrees; x+=checkSize)
				if (yCriterion ^ (++xCounter & 1)) glRectf(x, y, x+checkSize, y+checkSize); 
		}
	}
	//	[t logMilliseconds];
}



- (void) drawRect:(NSRect)rect {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
	// NSLog(@"pattern: %@", stimagePatternName);
	// NSLog(@"elementSizeInDeg: %f", elementSizeInDeg);
	screenWidthInPixels = rect.size.width;  screenHeightInPixels = rect.size.height;
	[self calculateDimensions];  [self setForeBackColors];
	glClearColor(0, 0, 0, 0);  glClear(GL_COLOR_BUFFER_BIT);// | GL_DEPTH_BUFFER_BIT);
	glLoadIdentity();  glOrtho(screenLeftInDegrees, screenRightInDegrees, screenBottomInDegrees, screenTopInDegrees, -1.0, 1.0);
	switch (self.stimagePatternID) {
		case homogenous:
			[self drawBasicHomogenous];
			break;
		case checkerboard:
			[self drawBasicCheckerboard];
			break;
		case gratingSquare:
			break;
		case gratingSine:
			break;
		case scene:
			break;
		default:
			break;
	}
	[self drawFixCrossAtX: 0 Y:0 size: 0.3];
	//glFlush(); // For optimal performance, an application should not call glFlush immediately before calling flushBuffer.
}


- (id)init {	//	NSLog(@"%s", __PRETTY_FUNCTION__);
    self = [super init];
    if (self) {
    }
    
    return self;
}


- (void)dealloc {	// NSLog(@"%s", __PRETTY_FUNCTION__);
    [super dealloc];
}

@end
