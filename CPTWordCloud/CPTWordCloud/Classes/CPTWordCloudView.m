//
//  CPTWordCloudView.m
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//
//

#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>

#import "CPTWordCloudView.h"

@interface CPTWordCloudView () 
{
    NSMutableDictionary* wordRects;    
    NSString* lastTouchedWord;
    
    UIColor* highlightColor;
    NSArray* highlightedWords;
}

@end

@implementation CPTWordCloudView

- (void) baseInit
{
    self.layer.masksToBounds = TRUE;
    //self.layer.shouldRasterize = YES; // test
    
    //self.backgroundColor = [UIColor clearColor];
    _scalingFactor = 1;
}

- (id) initForWordCloud:(CPTWordCloud *)wordCloud;
{
    if (self = [super init])
    {
        self.cloud = wordCloud;
        [self baseInit];
    }
    return self;
}

- (id) initForWordCloud:(CPTWordCloud *)wordCloud withFrame:(CGRect)frame;
{
    if (self = [super initWithFrame:frame])
    {
        self.cloud = wordCloud;
        [self baseInit];
    }    
    return self;
}

- (void) dealloc
{
    _words = nil;
    
    lastTouchedWord = nil;
    wordRects = nil;
    
    highlightColor = nil;
    highlightedWords = nil;
}

#pragma mark - view lifecycle

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (true == CGSizeEqualToSize(self.frame.size, self.cloud.cloudSize)) return;
    self.cloud.cloudSize = self.frame.size;
}

#pragma mark - CPTWordCloudDelegate

- (void) wordCloudDidGenerateCloud:(CPTWordCloud*)wc sortedWordArray:(NSArray*)words scalingFactor:(double)scalingFactor xShift:(double)xShift yShift:(double)yShift
{
    _words = words;
    _scalingFactor = scalingFactor;
    _xShift = xShift;
    _yShift = yShift;
    
    wordRects = [[NSMutableDictionary alloc] initWithCapacity:self.words.count];
    for (CPTWord* word in self.words)
    {
        float w = word.bounds.size.width * self.scalingFactor;
        float h = (word.bounds.size.height/2) * self.scalingFactor; // FIXME: not sure why word height is x2
        float x = self.xShift + word.bounds.origin.x * self.scalingFactor;
        float y =  self.bounds.size.height - (self.yShift + word.bounds.origin.y * self.scalingFactor) - h;
        [wordRects setObject:[NSValue valueWithCGRect:CGRectMake(x, y, w, h)] forKey:word.text];
    }
    
    [self setNeedsDisplay];
}

#pragma mark - public

- (void) setBorderColor:(UIColor*)borderColor
{
    self.layer.borderColor = borderColor.CGColor;
}

- (UIColor*) borderColor
{
    return [UIColor colorWithCGColor:self.layer.borderColor];
}

- (void) setBorderWidth:(float)borderWidth
{
    self.layer.borderWidth = borderWidth;
}

- (float) borderWidth
{
    return self.layer.borderWidth;
}

- (void) setCornerRadius:(float)cornerRadius
{
    self.layer.cornerRadius= cornerRadius;
}

- (float) cornerRadius
{
    return self.layer.cornerRadius;
}

-(void) highlightWord:(NSString *)stringWord;
{
    if (nil != stringWord && 0 < stringWord.length) {
        NSMutableSet *newHighlightWords = [NSMutableSet new];
        for (CPTWord *word in highlightedWords) {
            [newHighlightWords addObject:word.text];
        }
        [newHighlightWords addObject:stringWord];
        [self highlightWords:[newHighlightWords allObjects] color:[UIColor orangeColor]];
    }
    else {
        [self clearHighlights];
    }
}

- (void) highlightWords:(NSArray*)stringWords color:(UIColor*)color
{
    highlightColor = color;
    NSIndexSet *highlightWordsIndexSet = [self.words indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CPTWord *word = (CPTWord *)obj;
        NSIndexSet *stringWordsIndexSet = [stringWords indexesOfObjectsPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *stringWord = (NSString *)obj;
            return [stringWord.lowercaseString isEqualToString:word.text.lowercaseString];
        }];
        return 0 < [stringWordsIndexSet count];
    }];
    highlightedWords = [self.words objectsAtIndexes:highlightWordsIndexSet];
    
    [self setNeedsDisplay];
}

- (void) clearHighlights
{
    highlightColor = nil;
    highlightedWords = nil;
    
    [self setNeedsDisplay];
}

#pragma mark - private

- (void) drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
        
    // set the coordinates for iOS, as seen here:
    // https://developer.apple.com/library/mac/#documentation/graphicsimaging/conceptual/drawingwithquartz2d/dq_text/dq_text.html
    CGContextTranslateCTM(c, 0, self.bounds.size.height);
    CGContextScaleCTM(c, 1, -1);
    
    CGContextClearRect(c, self.bounds);
    
    CGContextSetFillColorWithColor(c, self.backgroundColor.CGColor);
    CGContextFillRect(c, self.bounds);
    
    if (!self.words.count) return;
    
    for (CPTWord* word in self.words)
    {
        UIColor* color = [highlightedWords containsObject:word] ? highlightColor : word.color;
        UIColor *backColor = [UIColor clearColor];
        
        UIFont *font = word.font;
        NSDictionary *attrsDictionary = @{ NSFontAttributeName : font,
                                           NSForegroundColorAttributeName : color,
                                           NSBackgroundColorAttributeName : backColor
        };

        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:word.text attributes:attrsDictionary];
        CFAttributedStringRef cfAttrString  = (__bridge CFAttributedStringRef)attrString;
        
        CTLineRef line = CTLineCreateWithAttributedString(cfAttrString);
        
        CGContextSetTextMatrix(c, CGAffineTransformIdentity);
        
        CGContextSaveGState(c);
        
        CGContextTranslateCTM(c, self.xShift + word.bounds.origin.x * self.scalingFactor, self.yShift + word.bounds.origin.y * self.scalingFactor);
        
        if (word.isRotated) {
            CGContextRotateCTM(c, M_PI / 2.0f);
            CGContextTranslateCTM(c, 0, -word.bounds.size.width);
        }
        
        CTLineDraw(line, c);
        CFRelease(line);
        
        CGContextRestoreGState(c);
    }
}

// the hitTest selector below ensures that this will only be called when a word has been tapped
- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    if ([self.delegate respondsToSelector:@selector(wordCloudView:didTapWord:atRect:)])
    {
        NSValue* value = [wordRects objectForKey:lastTouchedWord];        
        [self.delegate wordCloudView:self didTapWord:lastTouchedWord atRect:value.CGRectValue];
    }
    else {
        if (nil != lastTouchedWord) {
            [self highlightWord:lastTouchedWord];
        }
    }
}

// if the point is contained within the bounds of a word, save the point and the relevant word.
// otherwise, return nil to indicate that the point is not contained within this view.
- (UIView*) hitTest:(CGPoint)point withEvent:(UIEvent*)event
{
    lastTouchedWord = nil;
    for (NSString* word in wordRects.allKeys)
    {
        CGRect rect = [[wordRects objectForKey:word] CGRectValue];
        if (CGRectContainsPoint(rect, point))
        {
            lastTouchedWord = word;
            return self;
        }
    }
    
    if (nil == lastTouchedWord) {
        [self clearHighlights];
    }
    return nil;
}

@end
