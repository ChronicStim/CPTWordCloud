//
//  CPTWord.m
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import "CPTWord.h"

@implementation CPTWord

- (id) initWithWord:(NSString*)word count:(int)count
{
    if (self = [super init])
    {
        _text = word;
        _count = count;
        _color = [UIColor blackColor];
        _scalingTransform = CGAffineTransformIdentity;
        _rotated = NO;
        _stopword  = NO;
        _wordGlyphBounds = CGRectZero;
        _wordOrigin = CGPointZero;
    }
    return self;
}

- (void) dealloc
{
    _text = nil;
    _color = nil;
    _font = nil;
}

- (void) incrementCount
{
    _count++;
}

- (void) decrementCount
{
    _count--;
}

- (void)setCount:(int)count
{
    _count = count;
}

-(CGPoint)wordOriginWithScaling:(BOOL)includeScaling;
{
    CGPoint wordOrigin = self.wordOrigin;
    if (includeScaling) {
        wordOrigin = CGPointApplyAffineTransform(wordOrigin, self.scalingTransform);
    }
    return wordOrigin;
}

-(CGRect)wordRectForCurrentOriginWithScaling:(BOOL)includeScaling;
{
    CGRect wordRect = CGRectMake(self.wordOrigin.x+self.wordGlyphBounds.origin.x, self.wordOrigin.y+self.wordGlyphBounds.origin.y, self.wordGlyphBounds.size.width, self.wordGlyphBounds.size.height);
//    CGRect wordRect = CGRectMake(self.wordOrigin.x, self.wordOrigin.y, self.wordGlyphBounds.size.width, self.wordGlyphBounds.size.height);

    if (self.isRotated) {
        CGPoint rotationPoint = self.wordOrigin;
       wordRect = CGRectApplyAffineTransform(wordRect, CGAffineTransformMakeTranslation(-rotationPoint.x,-rotationPoint.y));
        wordRect = CGRectApplyAffineTransform(wordRect, CGAffineTransformMakeRotation(M_PI/2.0f));
        wordRect = CGRectApplyAffineTransform(wordRect, CGAffineTransformMakeTranslation(rotationPoint.x, rotationPoint.y));
    }
    
    if (includeScaling) {
        CGPoint scalePoint = self.wordOrigin;
        wordRect = CGRectApplyAffineTransform(wordRect, CGAffineTransformMakeTranslation(-scalePoint.x,-scalePoint.y));
        wordRect = CGRectApplyAffineTransform(wordRect, self.scalingTransform);
        wordRect = CGRectApplyAffineTransform(wordRect, CGAffineTransformMakeTranslation(scalePoint.x, scalePoint.y));
    }
    
    return wordRect;
}

//
//- (NSString *) description
//{
//    return [NSString stringWithFormat:@"%@ (%d) at %@", _text, _count, NSStringFromCGRect(rect)];
//}

@end
