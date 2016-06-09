//
//  CloudLayoutOperation.m
//  LionAndLamb
//
//  Created by Peter Jensen on 4/28/15.
//  Copyright (c) 2015 Peter Christian Jensen.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "CloudLayoutOperation.h"
#import "CloudWord.h"
#import "QuadTree.h"

#import "UIFont+CloudSettings.h"

@import CoreText;

@interface CloudLayoutOperation ()
/**
 The name of the font that the cloud will use for its words
 */
@property (nonatomic, strong) NSString *cloudFont;
/**
 A strong reference to our cloud's list of words
 */
@property (nonatomic, strong) NSArray *cloudWords;
/**
 The size of the container that the words must fit in
 */
@property (nonatomic, assign) CGRect containerFrame;
/**
 The scale of the container that the words must fit in
 
 @note This is the same as [[UIScreen mainScreen] scale]
 */
@property (nonatomic, assign) CGFloat containerScale;
/**
 A weak reference to the cloud layout operation's delegate
 */
@property (nonatomic, weak) id<CloudLayoutOperationDelegate> delegate;
/**
 A strong reference to a quadtree of cloud word (glyph) bounding rects
 */
@property (nonatomic, strong) QuadTree *glyphBoundingRects;

@end

@implementation CloudLayoutOperation

@synthesize cloudFont = _cloudFont;
@synthesize cloudWords = _cloudWords;
@synthesize containerFrame = _containerFrame;
@synthesize containerScale = _containerScale;
@synthesize delegate = _delegate;
@synthesize glyphBoundingRects = _glyphBoundingRects;

#pragma mark - Initialization

- (instancetype)initWithCloudWords:(NSArray *)cloudWords fontName:(NSString *)fontName forContainerWithFrame:(CGRect)containerFrame scale:(CGFloat)containerScale delegate:(id<CloudLayoutOperationDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        // Custom initialization

        _cloudWords = [[NSArray alloc] initWithArray:cloudWords];
        _cloudFont = fontName;
        _containerFrame = containerFrame;
        _containerScale = containerScale;
        _delegate = delegate;

        _glyphBoundingRects = [[QuadTree alloc] initWithFrame:containerFrame];
    }
    
    // NSLog(@"%@", cloudWords);
    return self;
}

#pragma mark - Public methods

//#ifdef DEBUG
//- (NSString *)debugDescription
//{
//    return [NSString stringWithFormat:@"<%@: %p> container size = (%.0f %.0f); delegate = %p; words = %@", self.class, self, self.containerFrame.width, self.containerFrame.height, self.delegate, self.cloudWords.debugDescription];
//}
//#endif

#pragma mark - Private methods

- (void)main
{

    if ([self isCancelled]) { return; }

    [self normalizeWordWeights];

    if ([self isCancelled]) { return; }

    [self assignColorsForWords];

    if ([self isCancelled]) { return; }
    
    [self assignPreferredPlacementsForWords];

    if ([self isCancelled]) { return; }

    [self reorderWordsByDescendingWordArea];

    if ([self isCancelled]) { return; }
    
    [self layoutCloudWords];
}

- (void)normalizeWordWeights
{
    // Determine minimum and maximum weight of words

    CGFloat minWordCount = [[self.cloudWords valueForKeyPath:@"@min.wordCount"] doubleValue];
    CGFloat maxWordCount = [[self.cloudWords valueForKeyPath:@"@max.wordCount"] doubleValue];

    CGFloat deltaWordCount = maxWordCount - minWordCount;
    CGFloat ratioCap = 4.0;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-statement-expression"
    CGFloat maxMinRatio = MIN((maxWordCount / minWordCount), ratioCap);
#pragma clang diagnostic pop

    // Start with these values, which will be decreased as needed that all the words may fit the container

    CGFloat fontMin = 0.0;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {

        fontMin = 20.0;
    
    } else {
        
        fontMin = 15.0;
    }
    
    CGFloat fontMax = fontMin * maxMinRatio;

    NSInteger dynamicTypeDelta = [UIFont lal_preferredContentSizeDelta];

    CGFloat containerArea = CGRectGetWidth(self.containerFrame) * CGRectGetHeight(self.containerFrame);
    BOOL wordAreaExceedscontainerFrame = NO;

    do
    {
        CGFloat wordArea = 0.0;
        wordAreaExceedscontainerFrame = NO;

        CGFloat fontRange = fontMax - fontMin;
        CGFloat fontStep = 3.0;

        // Normalize word weights

        for (CloudWord *word in self.cloudWords)
        {
            if ([self isCancelled])
            {
                return;
            }

            CGFloat scale = (word.wordCount.integerValue - minWordCount) / deltaWordCount;
            word.pointSize = fontMin + (fontStep * floor(scale * (fontRange / fontStep))) + dynamicTypeDelta;

            [word determineRandomWordOrientationInContainerWithSize:self.containerFrame.size scale:self.containerScale fontName:self.cloudFont];

            // Check to see if the current word fits in the container

            wordArea += word.boundsArea.doubleValue;

            if (wordArea >= containerArea || word.boundsSize.width >= CGRectGetWidth(self.containerFrame) || word.boundsSize.height >= CGRectGetHeight(self.containerFrame))
            {
                wordAreaExceedscontainerFrame = YES;
                fontMin--;
                fontMax = fontMin * maxMinRatio;
                break;
            }
        }
    } while (wordAreaExceedscontainerFrame);

    return;
}

/**
 */
- (void)assignColorsForWords
{
    CGFloat cloudWordsCount = self.cloudWords.count;

    [self.cloudWords enumerateObjectsUsingBlock:^(CloudWord *word, NSUInteger index, BOOL *stop) {
        *stop = [self isCancelled];
        CGFloat scale = (cloudWordsCount - index) / cloudWordsCount;
        [word determineColorForScale:scale];
    }];
}

/**
 Assigns a preferred placement location for each cloud word
 */
- (void)assignPreferredPlacementsForWords
{
    for (CloudWord *word in self.cloudWords)
    {
        if ([self isCancelled])
        {
            return;
        }

        // Assign a new preferred location for each word, as the size may have changed
        [word determineRandomWordPlacementInContainerWithSize:self.containerFrame.size scale:self.containerScale];
    }
}

- (void)reorderWordsByDescendingWordArea
{
    NSSortDescriptor *primarySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"boundsArea" ascending:NO];
    NSSortDescriptor *secondarySortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"pointSize" ascending:NO];
    self.cloudWords = [self.cloudWords sortedArrayUsingDescriptors:@[primarySortDescriptor, secondarySortDescriptor]];
}

- (void)layoutCloudWords
{
    for (CloudWord *word in self.cloudWords)
    {
        if ([self isCancelled])
        {
            return;
        }

        // Can the word can be placed at its preferred location?
        if ([self hasPlacedWord:word])
        {
            // Yes. Move on to the next word
            continue;
        }

        BOOL placed = NO;

        // If there's a spot for a word, it will almost always be found within 50 attempts.
        // Make 100 attempts to handle extremely rare cases where more than 50 attempts are needed to place a word

        for (NSUInteger attempt = 0; attempt < 100; attempt++)
        {
            // Try alternate placements along concentric circles
            if ([self hasFoundConcentricPlacementForWord:word])
            {
                placed = YES;
                break;
            }

            if ([self isCancelled])
            {
                return;
            }

            // No placement found centered on preferred location. Pick a new location at random
            [word determineRandomWordOrientationInContainerWithSize:self.containerFrame.size scale:self.containerScale fontName:self.cloudFont];
            [word determineRandomWordPlacementInContainerWithSize:self.containerFrame.size scale:self.containerScale];
        }

        // Reduce font size if word doesn't fit
        #ifdef DEBUG
        if (!placed)
        {
            NSLog(@"Couldn't find a spot for %@", [word debugDescription]);
        }
        #endif

    }
}

- (BOOL)hasFoundConcentricPlacementForWord:(CloudWord *)word
{
    CGRect containerRect = self.containerFrame;

    CGPoint savedCenter = word.boundsCenter;

    NSUInteger radiusMultiplier = 1; // 1, 2, 3, until radius too large for container

    BOOL radiusWithincontainerFrame = YES;

    // Placement terminated once no points along circle are within container

    while (radiusWithincontainerFrame)
    {
        // Start with random angle and proceed 360 degrees from that point

        NSUInteger initialDegree = arc4random_uniform(360);
        NSUInteger finalDegree = initialDegree + 360;
        
        // Try more points along circle as radius increases

        NSUInteger degreeStep = radiusMultiplier == 1 ? 15 : radiusMultiplier == 2 ? 10 : 5;
        
        CGFloat radius = radiusMultiplier * word.pointSize;

        radiusWithincontainerFrame = NO; // NO until proven otherwise

        for (NSUInteger degrees = initialDegree; degrees < finalDegree; degrees += degreeStep )
        {
            if ([self isCancelled])
            {
                return NO;
            }

            CGFloat radians = degrees * M_PI / 180.0;

            CGFloat x = cos(radians) * radius;
            CGFloat y = sin(radians) * radius;

            [word determineNewWordPlacementFromSavedCenter:savedCenter xOffset:x yOffset:y scale:self.containerScale];
            
            CGRect wordRect = [word paddedFrame];

            if (CGRectContainsRect(containerRect, wordRect))
            {
                radiusWithincontainerFrame = YES;
                if ([self hasPlacedWord:word atRect:wordRect])
                {
                    return YES;
                }
            }
        }

        // No placement found for word on points along current radius.  Try larger radius.

        radiusMultiplier++;
    }

    // The word did not fit along any concentric circles within the bounds of the container

    return NO;
}

- (BOOL)hasPlacedWord:(CloudWord *)word
{
    CGRect wordRect = [word paddedFrame];

    return [self hasPlacedWord:word atRect:wordRect];
}

- (BOOL)hasPlacedWord:(CloudWord *)word atRect:(CGRect)wordRect
{
    if ([self.glyphBoundingRects hasGlyphThatIntersectsWithWordRect:wordRect])
    {
        // Word intersects with another word
        return NO;
    }

    // Word doesn't intersect any (glyphs of) previously placed words.  Place it

    __weak id<CloudLayoutOperationDelegate> delegate = self.delegate;
    dispatch_async(dispatch_get_main_queue(), ^{
        [delegate insertWord:word.wordText pointSize:word.pointSize color:word.wordColor center:word.boundsCenter vertical:word.isWordOrientationVertical tappable: word.isWordTappable];
    });
    [self addGlyphBoundingRectsToQuadTreeForWord:word];

    return YES;
}

- (void)addGlyphBoundingRectsToQuadTreeForWord:(CloudWord *)word
{
    CGRect wordRect = word.frame;

    // Typesetting is always done in the horizontal direction

    // There's a small possibility that a particular typeset word using a particular font, may still not fit within a slightly larger frame.  Give the typesetter a very large frame, to ensure that any word, at any point size, can be typeset on a line

    CGRect horizontalFrame = CGRectMake(0.0,
                                        0.0,
                                        word.wordOrientationVertical ? CGRectGetHeight(self.containerFrame) : CGRectGetWidth(self.containerFrame),
                                        word.wordOrientationVertical ? CGRectGetWidth(self.containerFrame) : CGRectGetHeight(self.containerFrame));

    NSDictionary *attributes = @{ NSFontAttributeName : [UIFont fontWithName:self.cloudFont size:word.pointSize] };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:word.wordText attributes:attributes];

    CTFrameRef textFrame = NULL;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)(attributedString));
    CGPathRef drawingPath = CGPathCreateWithRect(horizontalFrame, NULL);
    textFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [attributedString length]), drawingPath, NULL);
    CFRelease(framesetter);
    CFRelease(drawingPath);

    CFArrayRef lines = CTFrameGetLines(textFrame);
    if (CFArrayGetCount(lines))
    {
        CGPoint lineOrigin;
        CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 1), &lineOrigin);
        CFArrayRef runs = CTLineGetGlyphRuns(CFArrayGetValueAtIndex(lines, 0));
        for (CFIndex runIndex = 0; runIndex < CFArrayGetCount(runs); runIndex++)
        {
            CTRunRef run = CFArrayGetValueAtIndex(runs, runIndex);
            CFDictionaryRef runAttributes = CTRunGetAttributes(run);
            CTFontRef font = CFDictionaryGetValue(runAttributes, NSFontAttributeName);
            for (CFIndex glyphIndex = 0; glyphIndex < CTRunGetGlyphCount(run); glyphIndex++)
            {
                CGPoint glyphPosition;
                CTRunGetPositions(run, CFRangeMake(glyphIndex, 1), &glyphPosition);

                CGGlyph glyph;
                CTRunGetGlyphs(run, CFRangeMake(glyphIndex, 1), &glyph);

                CGRect glyphBounds;
                CTFontGetBoundingRectsForGlyphs(font, kCTFontDefaultOrientation, &glyph, &glyphBounds, 1);

                CGRect glyphRect;

                CGFloat glyphX = lineOrigin.x + glyphPosition.x + CGRectGetMinX(glyphBounds);
                CGFloat glyphY = CGRectGetHeight(horizontalFrame) - (lineOrigin.y + glyphPosition.y + CGRectGetMaxY(glyphBounds));

                if ([word isWordOrientationVertical])
                {
                    glyphRect = CGRectMake(CGRectGetWidth(wordRect) - glyphY,
                                           glyphX,
                                           -(CGRectGetHeight(glyphBounds)),
                                           CGRectGetWidth(glyphBounds)
                                           );
                }
                else
                {
                    glyphRect = CGRectMake(glyphX,
                                           glyphY,
                                           CGRectGetWidth(glyphBounds),
                                           CGRectGetHeight(glyphBounds)
                                           );
                }

                glyphRect = CGRectOffset(glyphRect, CGRectGetMinX(wordRect), CGRectGetMinY(wordRect));
                [self.glyphBoundingRects insertBoundingRect:glyphRect];

//#ifdef DEBUG
//                __weak id<CloudLayoutOperationDelegate> delegate = self.delegate;
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [delegate insertBoundingRect:glyphRect];
//                });
//#endif
            }
        }
    }
    CFRelease(textFrame);
}

@end
