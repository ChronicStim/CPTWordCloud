//
//  CPTWordCloud.h
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTWord.h"

typedef NS_ENUM(NSUInteger, CPTWordFontSizeMode) {
    CPTWordFontSizeMode_N = 0,
    CPTWordFontSizeMode_sqrtN = 1,
    CPTWordFontSizeMode_logN = 2
};

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
/// Method which will be used to calculate the font size for displaying the words in the cloud
@property (nonatomic, assign) CPTWordFontSizeMode fontSizeMode;

// both colors default to black
@property (nonatomic, retain) UIColor* lowCountColor;
@property (nonatomic, retain) UIColor* highCountColor;

// words will minimally have this many pixels between them. defaults to (2,0)
@property (nonatomic) CGSize wordBorderSize;

// the size of the word wordCloud
@property (nonatomic) CGSize cloudSize;

// probability that words are rotated to a vertical position (defaults to 0%)
@property (nonatomic) CGFloat probabilityOfWordVertical;

// Use random fonts from system for each word. (defaults to NO)
@property (nonatomic, getter=isUsingRandomFontPerWord) BOOL usingRandomFontPerWord;
// An array of NSString fontNames that should be used when randomly assigning a font per word. This property is only used if usingRandomFontPerWord == YES
@property (nonatomic, strong) NSArray *selectableFontNames;

// Minimum count allowed in a word before it is removed from the word cloud (Default = 1); Used to allow zero count words
@property (nonatomic) NSInteger minimumWordCountAllowed;

///Convert all input words to be lowercase
///Recommended to be left to (Default == YES) whenever using input text that includes capitalization from sentence structures which could result in duplicate words otherwise (e.g. "The" == "the")
///Set property == NO when using input words that may include proper names or terms where you want to maintain capitalization of the input words.
@property (nonatomic, getter=isConvertingAllWordsToLowercase) BOOL convertingAllWordsToLowercase;

- (void)rebuild:(NSArray*)words;

// add words to the wordCloud
- (void)addWords:(NSString*)wordString delimiter:(NSString *)delimiter;
- (void)addWords:(NSArray*)words;
- (void)addWord:(NSString*)word;
- (void)addWordsWithCounts:(NSDictionary <NSString *, NSNumber *> *)wordsWithCounts;

// remove words from wordCloud
- (void)removeWord:(NSString*)word;
- (void)removeWords:(NSArray*)words;
- (void)removeAllWords;

// regenerate the wordCloud using current words and settings
- (void)generateCloud;

// reset the wordCloud, removing all words
- (void)resetCloud;

// Used for demo app
-(NSArray *)allSystemFontNames;

@end


@protocol CPTWordCloudDelegate <NSObject>

@optional

- (void)wordCloudDidGenerateCloud:(CPTWordCloud *)wc sortedWordArray:(NSArray *)words scalingFactor:(double)scalingFactor xShift:(double)xShift yShift:(double)yShift;

@end
