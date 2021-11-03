//
//  CPTWordCloud.h
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTWord.h"

@protocol CPTWordCloudDelegate;

@interface CPTWordCloud : NSObject

@property (nonatomic, weak) id <CPTWordCloudDelegate> delegate;

// if specified, display only the most frequent words. default is unlimited
@property (nonatomic) int maxNumberOfWords;

// ignore all words shorter than this. defaults to 3
@property (nonatomic) int minimumWordLength;

@property (nonatomic, retain) UIFont* font;
// font size of the word with fewer occurances. defaults to 10
@property (nonatomic) int minFontSize;
// font size of the word with most occurances. defaults to 100
@property (nonatomic) int maxFontSize;

// both colors default to black
@property (nonatomic, retain) UIColor* lowCountColor;
@property (nonatomic, retain) UIColor* highCountColor;

// words will minimally have this many pixels between them. defaults to 2
@property (nonatomic) int wordBorderSize;

// the size of the word cloud
@property (nonatomic) CGSize cloudSize;

- (void)rebuild:(NSArray*)words;

// add words to the cloud
- (void)addWords:(NSString*)wordString delimiter:(NSString *)delimiter;
- (void)addWords:(NSArray*)words;
- (void)addWord:(NSString*)word;

// remove words from cloud
- (void)removeWord:(NSString*)word;
- (void)removeWords:(NSArray*)words;
- (void)removeAllWords;

// regenerate the cloud using current words and settings
- (void)generateCloud;

// reset the cloud, removing all words
- (void)resetCloud;

@end


@protocol CPTWordCloudDelegate <NSObject>

@optional

- (void)wordCloudDidGenerateCloud:(CPTWordCloud *)wc sortedWordArray:(NSArray *)words scalingFactor:(double)scalingFactor xShift:(double)xShift yShift:(double)yShift;

@end
