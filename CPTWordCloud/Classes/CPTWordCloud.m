//
//  CPTWordCloud.m
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import "CPTWordCloud.h"
#import <GameplayKit/GameplayKit.h>
#import <math.h>
#import <CoreText/CoreText.h>
#import "CPTWordCloudSKScene.h"

@interface CPTWordCloud ()
{
    NSArray* _sortedWords;
    NSMutableDictionary* _wordCounts;
    CPTWord* _topWord;
    CPTWord* _bottomWord;

}
@property (nonatomic, strong) GKRandomSource *randomSource;
@property (nonatomic, strong) NSArray *arrayOfStopwords;
@property (nonatomic, strong, readwrite) CPTWordCloudSKScene *wordCloudSKScene;

- (void) incrementCount:(NSString*)word;
- (void) decrementCount:(NSString*)word;
-(void)setNeedsUpdateCloudSceneWithRegenerateNodes:(BOOL)regenerateNodes;

@end

@implementation CPTWordCloud
@synthesize font = _font;

- (id) init
{
    if (self = [super init])
    {
        // defaults
        _maxNumberOfWords = 0;
        _minimumWordLength = 1;
        _probabilityOfWordRotation = 0.0f;
        _usingRandomFontPerWord = NO;
        _selectableFontNames = [NSArray new];
        _wordWithCountOfZeroDisplayed = NO;
        _convertingAllWordsToLowercase = YES;
        _filteringStopWords = NO;
        _colorMappingHSBBased = NO;
        _rotationMode = CPTWordRotationMode_HorizVertOnly;
        _wordOutlineColor = [UIColor clearColor];
        
        _minFontSize = 10;
        _maxFontSize = 100;
        _font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:_minFontSize];
        
        _wordBorderSize = CGSizeMake(2,2);
        
        _cloudSize = CGSizeZero;
                
        self.lowCountColor = [UIColor colorWithRed:0.022 green:0.000 blue:0.751 alpha:1.000];
        self.highCountColor = [UIColor colorWithRed:0.751 green:0.000 blue:0.052 alpha:1.000];
        self.zeroCountColor = [UIColor darkGrayColor];
        
        _wordCounts = [[NSMutableDictionary alloc] init];        
    }
    return self;
}

- (void) dealloc
{
    _font = nil;
    
    _lowCountColor = nil;
    _highCountColor = nil;
    
    _sortedWords = nil;
    _wordCounts = nil;
    _topWord = nil;
    _bottomWord = nil;    
}

- (void) rebuild:(NSArray*)words
{
    [self removeAllWords];
    [self addWords:words];
}

- (void) addWords:(NSString*)wordString delimiter:(NSString*)delimiter
{
    if (!wordString.length) return;
    [self addWords:[wordString componentsSeparatedByString:delimiter]];
}

- (void) addWords:(NSArray*)words
{
    for (NSString* word in words)
    {
        [self addWord:word];
    }
}

- (void) addWord:(NSString*)word
{
    [self incrementCount:word];
}

- (void)addWordsWithCounts:(NSDictionary <NSString *, NSNumber *> *)wordsWithCounts;
{
    if (nil != wordsWithCounts) {
        for (NSString *word in wordsWithCounts.allKeys) {
            NSInteger count = (NSInteger)[wordsWithCounts[word] integerValue];
            [self processStringWord:word withCount:count];
        }
    }
}

- (void) removeWords:(NSArray*)words
{
    for (NSString* word in words)
    {
        [self removeWord:word];
    }
}

- (void) removeWord:(NSString*)word
{
    [self decrementCount:word];
}

-(NSArray *)sortedWords;
{
    return _sortedWords;
}

- (void) removeAllWords
{
    [_wordCounts removeAllObjects];
    _sortedWords = @[];
    _topWord = nil;
    _bottomWord = nil;
    
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
}

-(void)resetCloud;
{
    [self removeAllWords];
}

#pragma mark - SpriteKit methods

-(CPTWordCloudSKScene *)wordCloudSKScene;
{
    if (nil != _wordCloudSKScene) {
        return _wordCloudSKScene;
    }
    
    _wordCloudSKScene = [[CPTWordCloudSKScene alloc] initWordCloudSKSceneForWordCloud:self withSize:self.cloudSize];
    
    if (nil != self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(wordCloud:readyToPresentScene:)]) {
        [self.delegate wordCloud:self readyToPresentScene:_wordCloudSKScene];
    }
    
    return _wordCloudSKScene;
}

-(void)wordCloudHasBeenAddedToSKView;
{
    if (nil != self.delegate && [(NSObject *)self.delegate respondsToSelector:@selector(wordCloud:readyToPresentScene:)]) {
        [self.delegate wordCloud:self readyToPresentScene:self.wordCloudSKScene];
    }
}

#pragma mark - Stopword Handling

-(NSArray *)arrayOfStopwords;
{
    if (nil != _arrayOfStopwords) {
        return _arrayOfStopwords;
    }
    
    NSString *path = [[NSBundle bundleForClass:[CPTWordCloud class]] pathForResource:@"stopwords" ofType:@"csv" inDirectory:@"CPTWordCloud.bundle"];
    NSError *error = nil;
    NSString *contents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (nil != error) {
        NSLog(@"Could not read contents of stopwords file at path %@. Error %li : %@; %@",path,(long)error.code,error.description,error.userInfo);
    }
    _arrayOfStopwords = [contents componentsSeparatedByString:@"\r\n"];
    return _arrayOfStopwords;
}

-(BOOL)shouldFilterForStopwords;
{
    if (self.isFilteringStopWords) {
        return YES;
    }
    return NO;
}

-(void)checkForStopwordInWord:(CPTWord *)word;
{
    if ([self.arrayOfStopwords containsObject:[word.text lowercaseString]]) {
        word.stopword = YES;
    }
    else if (word.isStopword) {
        // Set flag to NO if it was previously set to YES (shouldn't happen)
        word.stopword = NO;
    }
}

#pragma mark - Fonts

-(UIFont *)font;
{
    if (nil != _font) {
        return _font;
    }
    // Assign the default font to ivar
    _font = [UIFont systemFontOfSize:self.minFontSize];

    return _font;
}

-(UIFont *)randomFontFromFontNames:(NSArray *)fontNames ofSize:(CGFloat)size;
{
    // Defaults to self.font in case where fontNames is nil or empty array
    UIFont *randomFont = [self.font fontWithSize:size];
    if (nil != fontNames && 0 < [fontNames count]) {
        GKRandomDistribution *randomDistribution = [[GKRandomDistribution alloc] initWithRandomSource:self.randomSource lowestValue:0 highestValue:(fontNames.count-1)];
        NSInteger nextInteger = [randomDistribution nextInt];
        randomFont = [UIFont fontWithName:fontNames[nextInteger] size:size];
    }
    return randomFont;
}

-(NSArray *)allSystemFontNames;
{
    NSMutableArray *mutArray = [NSMutableArray new];
    for (NSString *familyName in [UIFont familyNames]) {
        for (NSString *fontName in [UIFont fontNamesForFamilyName:familyName]) {
            [mutArray addObject:fontName];
        }
    }
    return [NSArray arrayWithArray:mutArray];
}

#pragma mark - Input Word Processing

-(NSString *)cleanWordForWord:(NSString *)word;
{
    NSString *cleanWord = nil;
    if (nil != word) {
        if (self.isConvertingAllWordsToLowercase) {
            cleanWord = [[word stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet].invertedSet] lowercaseString];
        } else {
            cleanWord = [word stringByTrimmingCharactersInSet:[NSCharacterSet letterCharacterSet].invertedSet];
        }
    }
    return cleanWord;
}

-(CPTWord *)wordForCleanWord:(NSString *)cleanWord;
{
    CPTWord* cptword = [_wordCounts valueForKey:cleanWord];
    if (!cptword)
    {
        cptword = [[CPTWord alloc] initWithWord:cleanWord count:0];
        [self checkForStopwordInWord:cptword];
        [_wordCounts setValue:cptword forKey:cleanWord];
    }
    return cptword;
}

- (void) incrementCount:(NSString*)word
{
    if (!word.length) return;
    // trim non-letter characters and convert to lower case
    NSString* cleanWord = [self cleanWordForWord:word];
    // ignore all words shorter than the minimum word length
    if (cleanWord.length < self.minimumWordLength) return;
        
    CPTWord* cptword = [self wordForCleanWord:cleanWord];
    [self updateWord:cptword withCount:cptword.count+1];
}

- (void) decrementCount:(NSString*)word
{
    if (!word.length) return;
    // trim non-letter characters and convert to lower case
    NSString* cleanWord = [self cleanWordForWord:word];
    
    CPTWord* cptword = [self wordForCleanWord:cleanWord];
    [self updateWord:cptword withCount:cptword.count-1];
}

-(void)processStringWord:(NSString *)word withCount:(NSInteger)count;
{
    if (!word.length) return;
    // trim non-letter characters and convert to lower case
    NSString* cleanWord = [self cleanWordForWord:word];
    // ignore all words shorter than the minimum word length
    if (cleanWord.length < self.minimumWordLength) return;
    
    CPTWord* cptword = [self wordForCleanWord:cleanWord];
    [self updateWord:cptword withCount:count];
}

-(void)updateWord:(CPTWord *)cptWord withCount:(NSInteger)count;
{
    if (nil != cptWord) {
        
        cptWord.count = (int)count;
    }
}

-(void)selectBoundaryWords;
{
    if (nil != _sortedWords && 0 < [_sortedWords count]) {
        _topWord = _sortedWords.firstObject;
        _bottomWord = _sortedWords.lastObject;
    }
    else {
        _sortedWords = @[];
        _topWord = nil;
        _bottomWord = nil;
    }
}

-(void)filterAndSortWords;
{
    NSUInteger minCountAllowed = (self.isWordWithCountOfZeroDisplayed ? 0 : 1);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %li",@"count",minCountAllowed];
    if ([self shouldFilterForStopwords]) {
        NSPredicate *stopwordsPredicate = [NSPredicate predicateWithFormat:@"%K == NO",@"stopword"];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate,stopwordsPredicate]];
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"count" ascending:FALSE];
    _sortedWords = [[_wordCounts.allValues filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
}

-(GKRandomSource *)randomSource;
{
    if (nil != _randomSource) {
        return _randomSource;
    }
    
    _randomSource = [[GKRandomSource alloc] init];
    return _randomSource;
}

-(BOOL)nextRandomBoolWithProbabilityForYes:(CGFloat)probability;
{
    if (0.0f == probability) {
        return NO;
    }
    
    GKRandomDistribution *randomDistribution = [[GKRandomDistribution alloc] initWithRandomSource:self.randomSource lowestValue:1 highestValue:100];
    float randomFloat = [randomDistribution nextUniform];
    if (randomFloat <= probability) {
        return YES;
    }
    return NO;
}

-(CGFloat)scaledValueForOccuranceCount:(NSUInteger)count minValue:(CGFloat)minValue maxValue:(CGFloat)maxValue usingScalingMode:(CPTWordScalingMode)scalingMode;
{
    CGFloat scaledValue = 0.0f;
    if (minValue == maxValue) {
        scaledValue = minValue;
    }
    else {
        switch (scalingMode) {
            case CPTWordScalingMode_rank: {
                // Use rank order to determine font size from min to max (relative difference in count between words doesn't effect sizing)
                NSSet *uniqueCountsInSortedWords = [NSSet setWithArray:[_sortedWords valueForKeyPath:@"count"]];
                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intValue" ascending:YES comparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    if ([obj1 integerValue] > [obj2 integerValue]) {
                        return (NSComparisonResult)NSOrderedDescending;
                    }
                    
                    if ([obj1 integerValue] < [obj2 integerValue]) {
                        return (NSComparisonResult)NSOrderedAscending;
                    }
                    return (NSComparisonResult)NSOrderedSame;
                }];
                NSArray *orderedUniqueCountsInSortedWords = [uniqueCountsInSortedWords sortedArrayUsingDescriptors:@[sortDescriptor]];
                NSInteger countOfRanks = orderedUniqueCountsInSortedWords.count;
                NSInteger currentRank = [orderedUniqueCountsInSortedWords indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    return [obj integerValue] == count;
                }];
                if (1 < countOfRanks) {
                    scaledValue = (minValue + (float)(maxValue-minValue)*(float)currentRank/((float)countOfRanks-1.0f));
                } else {
                    scaledValue = maxValue;
                }
            }   break;
            case CPTWordScalingMode_linearN: {
                // Use word frequency (count) to determine font sizing from min to max along a linear ramp
                CGFloat maxCount = (float)_topWord.count;
                CGFloat minCount = (float)_bottomWord.count;
                scaledValue = minValue + ((maxValue - minValue) / (maxCount - minCount)) * (count-minCount);
            }   break;
            case CPTWordScalingMode_expN: {
                // Use word frequency (count) to determine font sizing from min to max based on an exponential ramp
                CGFloat maxCount = (float)_topWord.count;
                CGFloat minCount = (float)_bottomWord.count;
                CGFloat b = (1/(minCount-maxCount))*log10f((float)minValue/(float)maxValue);
                CGFloat a = (float)maxValue / powf(10,b * maxCount);
                scaledValue = a * powf(10,b * (float)count);
            }   break;
            case CPTWordScalingMode_logN: {
                // Use word frequency (count) to determine font sizing from min to max based on an logarithmic ramp
                CGFloat maxCount = (float)_topWord.count;
                CGFloat minCount = (_bottomWord.count > 0) ? (float)_bottomWord.count : 1.0f;
                CGFloat a = ((float)minValue - (float)maxValue)/(log10f(minCount)-log10f(maxCount));
                CGFloat b = powf(10, (float)minValue/a)/minCount;
                scaledValue = a * log10f(b * (float)count);
            }   break;
            default:
                break;
        }
    }
    return scaledValue;
}

-(CGFloat)fontSizeForOccuranceCount:(NSInteger)count usingScalingMode:(CPTWordScalingMode)fontSizeMode;
{
    CGFloat finalFontSize = [self scaledValueForOccuranceCount:count minValue:self.minFontSize maxValue:self.maxFontSize usingScalingMode:fontSizeMode];

    return finalFontSize;
}

-(UIColor *)wordColorForOccuranceCount:(NSUInteger)count usingScalingMode:(CPTWordScalingMode)sizingMode;
{
    CGFloat red1 = 0.0f;
    CGFloat green1 = 0.0f;
    CGFloat blue1 = 0.0f;
    CGFloat alpha1 = 0.0f;
    CGFloat red2 = 0.0f;
    CGFloat green2 = 0.0f;
    CGFloat blue2 = 0.0f;
    CGFloat alpha2 = 0.0f;
    CGFloat red3 = 0.0f;
    CGFloat green3 = 0.0f;
    CGFloat blue3 = 0.0f;
    CGFloat alpha3 = 0.0f;

    if (self.isColorMappingHSBBased) {
        [self.lowCountColor getHue:&red1 saturation:&green1 brightness:&blue1 alpha:&alpha1];
        [self.highCountColor getHue:&red2 saturation:&green2 brightness:&blue2 alpha:&alpha2];
    }
    else {
        [self.lowCountColor getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
        [self.highCountColor getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
    }
    
    red3 = [self scaledValueForOccuranceCount:count minValue:red1*255.0f+1.0f maxValue:red2*255.0f+1.0f usingScalingMode:sizingMode];
    green3 = [self scaledValueForOccuranceCount:count minValue:green1*255.0f+1.0f maxValue:green2*255.0f+1.0f usingScalingMode:sizingMode];
    blue3 = [self scaledValueForOccuranceCount:count minValue:blue1*255.0f+1.0f maxValue:blue2*255.0f+1.0f usingScalingMode:sizingMode];
    alpha3 = [self scaledValueForOccuranceCount:count minValue:alpha1*255.0f+1.0f maxValue:alpha2*255.0f+1.0f usingScalingMode:sizingMode];

    UIColor *finalColor = nil;
    if (self.isColorMappingHSBBased) {
        finalColor = [UIColor colorWithHue:(red3-1.0f)/255.0f saturation:(green3-1.0f)/255.0f brightness:(blue3-1.0f)/255.0f alpha:(alpha3-1.0f)/255.0f];
    }
    else {
        finalColor = [UIColor colorWithRed:(red3-1.0f)/255.0f green:(green3-1.0f)/255.0f blue:(blue3-1.0f)/255.0f alpha:(alpha3-1.0f)/255.0f];
    }
    
    //NSLog(@"Mode: %i; Count: %i; Color: %@",(int)sizingMode,(int)count,finalColor.debugDescription);
    
    return finalColor;
}

/// Returns all word objects to a wordFrame == CGRectZero prior to the generation process.
-(void)zeroExistingWordFrames;
{
    for (CPTWord *word in _sortedWords) {
        word.wordGlyphBounds = CGRectZero;
        word.wordOrigin = CGPointZero;
        word.scalingTransform = CGAffineTransformIdentity;
        word.rotationTransform = CGAffineTransformIdentity;
    }
}

-(void)setNeedsUpdateCloudSceneWithRegenerateNodes:(BOOL)regenerateNodes;
{
    @synchronized(self)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateCloudSceneWithRegenerateNodes:) object:@(YES)];
        [self performSelector:@selector(updateCloudSceneWithRegenerateNodes:) withObject:@(regenerateNodes) afterDelay:0.1f];
    }
}

/// Triggers an update of the SKScene for the wordCloud in order to either adjust properties (e.g. colors, word outlines) or generate a new cloud
/// @param regenerateNodes Determines whether to use the existing SKScene nodes or to regenerate all new nodes. In most cases, this parameter will be YES, but in situations where something like font color has changed, the same nodes can be utilized so that the word positions do not change - only the word colors are altered.
-(void)updateCloudSceneWithRegenerateNodes:(NSNumber *)regenerateNodes;
{
    BOOL regenerate = [regenerateNodes boolValue];
    if (!regenerate && [self.wordCloudSKScene hasExistingNodes]) {
        // If SKScene has been generated previously and regeneration is NOT desired
        [self.wordCloudSKScene updateExistingScene];
    }
    else {
        // Generate a new scene
        [self filterAndSortWords];
        [self selectBoundaryWords];
        
        [self.wordCloudSKScene generateSceneWithSortedWords:_sortedWords];
    }
}

-(CGAffineTransform)getRotationTransformationForProbabilityOfRotation:(CGFloat)probabilityOfRoation rotationMode:(CPTWordRotationMode)rotationMode;
{
    CGAffineTransform rotationTransform = CGAffineTransformMakeRotation([self getRotationAngleInRadiansForProbabilityOfRotation:probabilityOfRoation rotationMode:rotationMode]);
    return rotationTransform;
}

-(CGFloat)getRotationAngleInRadiansForProbabilityOfRotation:(CGFloat)probabilityOfRoation rotationMode:(CPTWordRotationMode)rotationMode;
{
    CGFloat rotationAngle = 0.0f;
    BOOL rotateWord = [self nextRandomBoolWithProbabilityForYes:probabilityOfRoation];
    if (rotateWord) {
        switch (rotationMode) {
            case CPTWordRotationMode_NoRotation: {
            }   break;
            case CPTWordRotationMode_HorizVertOnly: {
                // 2 options vert-right, vert-left; (we won't use upside-down as an option)
                int option = 0;
                do {
                    option = 1-arc4random()%3;  //(-1, 0, 1)
                } while (option == 0); // We don't want the zero case since we already predicted a non-horizontal word.
                rotationAngle = (M_PI_2 * option);
            }   break;
            case CPTWordRotationMode_Deg45: {
                // 4 options: vert-right, vert-left, 45-up, 45-down; (no upside down options)
                int option = 0;
                do {
                    option = 2-arc4random()%5;  //(-2, -1, 0, 1, 2)
                } while (option == 0); // We don't want the zero case since we already predicted a non-horizontal word.
                rotationAngle = (M_PI_4 * option);
            }   break;
            case CPTWordRotationMode_Deg30: {
                // 6 options: vert-right, vert-left, 30-up, 30-down, 60-up, 60-down; (no upside down options)
                int option = 0;
                do {
                    option = 3-arc4random()%7; //(3, 2, 1, 0, -1, -2, -3)
                } while (option == 0); // We don't want the zero case since we already predicted a non-horizontal word.
                rotationAngle = (M_PI_2/3.0f * option);
            }   break;
            default:
                break;
        }
    }
    
    return rotationAngle;
}

#pragma mark - accessors

- (void) setCloudSize:(CGSize)cloudSize
{
    if (true == CGSizeEqualToSize(cloudSize, self.cloudSize)) return;
    _cloudSize = cloudSize;
    if (nil != _wordCloudSKScene) {
        self.wordCloudSKScene.size = _cloudSize;
    }
    
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:NO];
}

- (void) setFont:(UIFont*)font
{
    if (font == self.font) return;    
    _font = font;
    
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
}

- (void) setMinFontSize:(int)minFontSize
{
    if (minFontSize == self.minFontSize) return;
    _minFontSize = minFontSize;
    
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
}

- (void) setMaxFontSize:(int)maxFontSize
{
    if (maxFontSize == self.maxFontSize) return;
    _maxFontSize = maxFontSize;
    
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
}

- (void) setWordBorderSize:(CGSize)wordBorderSize
{
    if (CGSizeEqualToSize(wordBorderSize, _wordBorderSize)) return;
    _wordBorderSize = wordBorderSize;
    
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
}

- (void) setLowCountColor:(UIColor*)color
{
    if (color == self.lowCountColor) return;
    _lowCountColor = color;
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:NO];
}

- (void) setHighCountColor:(UIColor*)color
{
    if (color == self.highCountColor) return;
    _highCountColor = color;
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:NO];
}

- (void)setZeroCountColor:(UIColor *)zeroCountColor;
{
    if (zeroCountColor == self.zeroCountColor) return;
    _zeroCountColor = zeroCountColor;
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:NO];
}

- (void) setMaxNumberOfWords:(int)maxNumberOfWords
{
    if (maxNumberOfWords == self.maxNumberOfWords) return;
    
    _maxFontSize = maxNumberOfWords;
    [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
}

- (void) setMinimumWordLength:(int)minimumWordLength
{
    if (minimumWordLength == self.minimumWordLength) return;    
    _minimumWordLength = minimumWordLength;
    
    [self rebuild:[_wordCounts.allKeys copy]];
}

-(void)setProbabilityOfWordRotation:(CGFloat)probabilityOfWordRotation;
{
    if (probabilityOfWordRotation != _probabilityOfWordRotation) {
        _probabilityOfWordRotation = probabilityOfWordRotation;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setUsingRandomFontPerWord:(BOOL)usingRandomFontPerWord;
{
    if (usingRandomFontPerWord != _usingRandomFontPerWord) {
        _usingRandomFontPerWord = usingRandomFontPerWord;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setSelectableFontNames:(NSArray *)selectableFontNames;
{
    if (selectableFontNames != _selectableFontNames) {
        _selectableFontNames = selectableFontNames;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setWordWithCountOfZeroDisplayed:(BOOL)wordWithCountOfZeroDisplayed;
{
    if (wordWithCountOfZeroDisplayed != _wordWithCountOfZeroDisplayed) {
        _wordWithCountOfZeroDisplayed = wordWithCountOfZeroDisplayed;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setConvertingAllWordsToLowercase:(BOOL)convertingAllWordsToLowercase;
{
    if (convertingAllWordsToLowercase != _convertingAllWordsToLowercase) {
        _convertingAllWordsToLowercase = convertingAllWordsToLowercase;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setScalingMode:(CPTWordScalingMode)fontSizeMode;
{
    if (fontSizeMode != _scalingMode) {
        _scalingMode = fontSizeMode;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setRotationMode:(CPTWordRotationMode)rotationMode;
{
    if (rotationMode != _rotationMode) {
        _rotationMode = rotationMode;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setFilteringStopWords:(BOOL)filteringStopWords;
{
    if (filteringStopWords != _filteringStopWords) {
        _filteringStopWords = filteringStopWords;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:YES];
    }
}

-(void)setColorMappingHSBBased:(BOOL)colorMappingHSBBased;
{
    if (colorMappingHSBBased != _colorMappingHSBBased) {
        _colorMappingHSBBased = colorMappingHSBBased;
        [self setNeedsUpdateCloudSceneWithRegenerateNodes:NO];
    }
}

-(void)setWordOutlineColor:(UIColor *)wordOutlineColor;
{
    if (wordOutlineColor != _wordOutlineColor) {
        _wordOutlineColor = wordOutlineColor;
        self.wordCloudSKScene.wordOutlineColor = _wordOutlineColor;
    }
}

@end
