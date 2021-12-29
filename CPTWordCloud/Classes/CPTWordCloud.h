//
//  CPTWordCloud.h
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CPTWord.h"

typedef NS_ENUM(NSUInteger, CPTWordScalingMode) {
    CPTWordScalingMode_rank = 0,
    CPTWordScalingMode_linearN = 1,
    CPTWordScalingMode_expN = 2,
    CPTWordScalingMode_logN = 3
};

typedef NS_ENUM(NSUInteger, CPTWordRotationMode) {
    CPTWordRotationMode_NoRotation = 0,
    CPTWordRotationMode_HorizVertOnly = 1,
    CPTWordRotationMode_Deg45 = 2,
    CPTWordRotationMode_Deg30 = 3
};

@protocol CPTWordCloudDelegate;
@class CPTWordCloudSKScene, CPTWordCloudSKView;
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
/// Method which will be used to calculate the font size and color for displaying the words in the cloud
@property (nonatomic, assign) CPTWordScalingMode scalingMode;
/// Determines which rotation options are available to the wordCloud algorithm. Default == CPTWordRotationMode_HorizVertOnly
@property (nonatomic, assign) CPTWordRotationMode rotationMode;

// both colors default to black
/// Word color for the lowest count word in the cloud. Higher count words will be a gradation of this color and highCountColor. Defaults to blackColor
@property (nonatomic, retain) UIColor* lowCountColor;
/// Word color for the highest count word in the cloud. Lower count words will be a gradation of this color and lowCountColor. Defaults to blackColor
@property (nonatomic, retain) UIColor* highCountColor;
/// Determines if the algorithm calculating word color uses a blending of RGB values or HSB values. Default == NO which means RGB values are used. If YES, then HSB values are used. The algorithm relies on the sizingMode for scaling between the two end colors.
/// HSB mode will give a much more colorful wordcloud, while the RGB mode will produce more consistently colored tones.
/// RGB mode combined with the EXP sizingMode may produce darker colors for mid-count words and may be a less desirable combination. In this situation, switch to the HSB mode.
@property (nonatomic, getter=isColorMappingHSBBased) BOOL colorMappingHSBBased;

/// Color used for drawing rect outline around word for debugging purposes (Default = Clear)
@property (nonatomic, retain) UIColor* wordOutlineColor;

/// When words with count==0 are included in the wordCloud (minimumWordCountAllowed == 0), then this color will be used for any word with a count <= 0. Defaults to darkGrayColor
@property (nonatomic, retain) UIColor* zeroCountColor;

// words will minimally have this many pixels between them. defaults to (2,0)
@property (nonatomic) CGSize wordBorderSize;

// the size of the word wordCloud
@property (nonatomic) CGSize cloudSize;

// probability that words are rotated to a vertical position (defaults to 0%)
@property (nonatomic) CGFloat probabilityOfWordRotation;

// Use random fonts from system for each word. (defaults to NO)
@property (nonatomic, getter=isUsingRandomFontPerWord) BOOL usingRandomFontPerWord;
// An array of NSString fontNames that should be used when randomly assigning a font per word. This property is only used if usingRandomFontPerWord == YES
@property (nonatomic, strong) NSArray *selectableFontNames;

/// Allows wordCloud to display any words with a count of ZERO. Defaults to NO.
/// When zero count words are displayed, they use the zeroCountColor and minFontSize.
@property (nonatomic, getter=isWordWithCountOfZeroDisplayed) BOOL wordWithCountOfZeroDisplayed;

///Convert all input words to be lowercase
///Recommended to be left to (Default == YES) whenever using input text that includes capitalization from sentence structures which could result in duplicate words otherwise (e.g. "The" == "the")
///Set property == NO when using input words that may include proper names or terms where you want to maintain capitalization of the input words.
@property (nonatomic, getter=isConvertingAllWordsToLowercase) BOOL convertingAllWordsToLowercase;

/// Flag used to trigger the removal of words from the input stream that don't typically add value or meaning to the word cloud (e.g. a, the, I, he, she, it) (Default == YES)
@property (nonatomic, getter=isFilteringStopWords) BOOL filteringStopWords;

/// SpriteKit scene used to build the wordCloud
@property (nonatomic, strong, readonly) CPTWordCloudSKScene *wordCloudSKScene;

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
-(NSArray *)sortedWords;
- (void)generateCloud;
-(CGFloat)fontSizeForOccuranceCount:(NSInteger)count usingScalingMode:(CPTWordScalingMode)fontSizeMode;
-(UIColor *)wordColorForOccuranceCount:(NSUInteger)count usingScalingMode:(CPTWordScalingMode)sizingMode;
-(CGFloat)getRotationAngleInRadiansForProbabilityOfRotation:(CGFloat)probabilityOfRoation rotationMode:(CPTWordRotationMode)rotationMode;
-(UIFont *)randomFontFromFontNames:(NSArray *)fontNames ofSize:(CGFloat)size;

// reset the wordCloud, removing all words
- (void)resetCloud;

// Used for demo app
-(NSArray *)allSystemFontNames;

@end


@protocol CPTWordCloudDelegate <NSObject>

@optional
- (void)wordCloud:(CPTWordCloud *)wc readyToPresentScene:(CPTWordCloudSKScene *)scene;

@end
