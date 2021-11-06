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
@property (nonatomic, readonly) int count;
@property (nonatomic) CGRect bounds;
@property (nonatomic, retain) UIColor* color;
@property (nonatomic, retain) UIFont* font;
@property (nonatomic, getter=isRotated) BOOL rotated;
@property (nonatomic) CGAffineTransform transform;
//@property (nonatomic) BOOL countChanged;

- (id) initWithWord:(NSString*)word count:(int)count;

- (void) incrementCount;
- (void) decrementCount;

@end
