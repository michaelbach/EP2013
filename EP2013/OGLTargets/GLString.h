//
// File:		GLString.h 
//				(Originally StringTexture.h)
//
// Abstract:	Uses Quartz to draw a string into an OpenGL texture
//
// Version:		1.1 - Minor enhancements and bug fixes.
//				1.0 - Original release.
// Copyright ( C ) 2003-2007 Apple Inc. All Rights Reserved.
//
//	History
//	=======
//
//	2011-11-21	switched to "@property" in .h
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLContext.h>

@interface NSBezierPath (RoundRect)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;
@end

@interface GLString : NSObject {
	CGLContextObj cgl_ctx; // current context at time of texture creation
	GLuint texName;
	NSSize texSize;
	NSColor *textColor; // default is opaque white
	NSColor *boxColor; // default transparent or none
	NSColor *borderColor; // default transparent or none
	BOOL staticFrame; // default in NO
	BOOL antialias;	// default to YES
	NSSize marginSize; // offset or frame size, default is 4 width 2 height
	NSSize frameSize; // offset or frame size, default is 4 width 2 height
	float	cRadius; // Corner radius, if 0 just a rectangle. Defaults to 4.0f
}

@property (readwrite) BOOL antialias;

// this API requires a current rendering context and all operations will be performed in regards to thar context
// the same context should be current for all method calls for a particular object instance

// designated initializer
- (id) initWithAttributedString:(NSAttributedString *)attributedString withTextColor:(NSColor *)color withBoxColor:(NSColor *)color withBorderColor:(NSColor *)color;

- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs withTextColor:(NSColor *)color withBoxColor:(NSColor *)color withBorderColor:(NSColor *)color;

// basic methods that pick up defaults
- (id) initWithString:(NSString *)aString withAttributes:(NSDictionary *)attribs;
- (id) initWithAttributedString:(NSAttributedString *)attributedString;

- (void) dealloc;

@property (readwrite) GLuint texName; // 0 if no texture allocated
@property (readonly) NSSize texSize; // actually size of texture generated in texels, (0, 0) if no texture allocated

@property (retain) NSColor* textColor; // pre-multiplied default text color (includes alpha) string attributes could override this
@property (retain) NSColor* boxColor; // pre-multiplied box color (includes alpha) alpha of 0.0 means no background box
@property (retain) NSColor* borderColor; // pre-multiplied border color (includes alpha) alpha of 0.0 means no border
@property (readonly) BOOL staticFrame; // returns whether or not a static frame will be used

@property (readonly) NSSize frameSize; // returns either dynamc frame (text size + margins) or static frame size (switch with staticFrame)

@property (readonly) NSSize marginSize; // current margins for text offset and pads for dynamic frame

- (void) genTexture; // generates the texture without drawing texture to current context
- (void) drawWithBounds:(NSRect)bounds; // will update the texture if required due to change in settings (note context should be setup to be orthographic scaled to per pixel scale)
- (void) drawAtPoint:(NSPoint)point;

// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size; // set offset size and size to fit with offset
- (void) useStaticFrame:(NSSize)size; // set static frame size and size to frame
- (void) useDynamicFrame; // set static frame size and size to frame

- (void) setString:(NSAttributedString *)attributedString; // set string after initial creation
- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation


@end

