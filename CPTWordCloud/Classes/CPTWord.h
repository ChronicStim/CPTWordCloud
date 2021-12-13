//
//  CPTWord.h
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CPTWord : NSObject

@property (nonatomic, retain, readonly) NSString* text;
@property (nonatomic) int count;
@property (nonatomic) CGPoint wordOrigin;
@property (nonatomic) CGRect wordGlyphBounds;
@property (nonatomic, retain) UIColor* color;
@property (nonatomic, retain) UIFont* font;
@property (nonatomic, getter=isRotated, readonly) BOOL rotated;
@property (nonatomic) CGAffineTransform rotationTransform;
@property (nonatomic) CGAffineTransform scalingTransform;
@property (nonatomic, getter=isStopword) BOOL stopword;

- (id) initWithWord:(NSString*)word count:(int)count;

- (void) incrementCount;
- (void) decrementCount;

-(CGPoint)wordOriginWithScaling:(BOOL)includeScaling;
-(CGRect)wordRectForCurrentOriginWithScaling:(BOOL)includeScaling;

@end
