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

-(CGRect)wordRectForCurrentOrigin;
{
    CGRect wordRect = CGRectMake(self.wordOrigin.x+self.wordGlyphBounds.origin.x, self.wordOrigin.y+self.wordGlyphBounds.origin.y, self.wordGlyphBounds.size.width, self.wordGlyphBounds.size.height);

    if (self.isRotated) {
        CGAffineTransform rotateTransform = CGAffineTransformMakeTranslation(CGRectGetMinX(wordRect), CGRectGetMinY(wordRect));
        rotateTransform = CGAffineTransformRotate(rotateTransform, 90);
        rotateTransform = CGAffineTransformMakeTranslation(-CGRectGetMinX(wordRect), -CGRectGetMinY(wordRect));
    }
    
    return CGRectApplyAffineTransform(wordRect, self.scalingTransform);
}

//
//- (NSString *) description
//{
//    return [NSString stringWithFormat:@"%@ (%d) at %@", _text, _count, NSStringFromCGRect(rect)];
//}

@end
