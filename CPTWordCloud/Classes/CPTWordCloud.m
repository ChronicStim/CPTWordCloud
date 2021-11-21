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

@interface CPTWordCloud ()
{
    NSArray* sortedWords;
    NSMutableDictionary* wordCounts;
    CPTWord* topWord;
    CPTWord* bottomWord;

    CGFloat lowCountColorComponents[4];
    CGFloat highCountColorComponents[4];
}
@property (nonatomic, strong) GKRandomSource *randomSource;
@property (nonatomic, strong) NSArray *arrayOfStopwords;

- (void) incrementCount:(NSString*)word;
- (void) decrementCount:(NSString*)word;
- (void) setNeedsGenerateCloud;
- (void) generateCloud;

- (CGColorRef) CGColorRefFromUIColor:(UIColor*)color CF_RETURNS_RETAINED;

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
        _probabilityOfWordVertical = 0.0f;
        _usingRandomFontPerWord = NO;
        _selectableFontNames = [NSArray new];
        _minimumWordCountAllowed = 1;
        _convertingAllWordsToLowercase = YES;
        _filteringStopWords = NO;
        
        _minFontSize = 10;
        _maxFontSize = 100;
        
        _wordBorderSize = CGSizeMake(2,2);
        
        _cloudSize = CGSizeZero;
                
        self.lowCountColor = [UIColor blackColor];
        self.highCountColor = [UIColor blackColor];
        
        wordCounts = [[NSMutableDictionary alloc] init];        
    }
    return self;
}

- (void) dealloc
{
    _font = nil;
    
    _lowCountColor = nil;
    _highCountColor = nil;
    
    sortedWords = nil;
    wordCounts = nil;
    topWord = nil;
    bottomWord = nil;
    
    //delete(lowCountColorComponents);
    //delete(highCountColorComponents);
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

- (void) removeAllWords
{
    [wordCounts removeAllObjects];
    sortedWords = @[];
    topWord = nil;
    bottomWord = nil;
    
    [self setNeedsGenerateCloud];
}

-(void)resetCloud;
{
    [self removeAllWords];
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
    CPTWord* cptword = [wordCounts valueForKey:cleanWord];
    if (!cptword)
    {
        cptword = [[CPTWord alloc] initWithWord:cleanWord count:0];
        [self checkForStopwordInWord:cptword];
        [wordCounts setValue:cptword forKey:cleanWord];
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
    if (nil != sortedWords && 0 < [sortedWords count]) {
        topWord = sortedWords.firstObject;
        bottomWord = sortedWords.lastObject;
    }
    else {
        topWord = nil;
        bottomWord = nil;
    }
}

-(void)filterAndSortWords;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %li",@"count",self.minimumWordCountAllowed];
    if ([self shouldFilterForStopwords]) {
        NSPredicate *stopwordsPredicate = [NSPredicate predicateWithFormat:@"%K == NO",@"stopword"];
        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate,stopwordsPredicate]];
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"count" ascending:FALSE];
    sortedWords = [[wordCounts.allValues filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    if (0 < [sortedWords count]) {
        topWord = sortedWords[0];
    }
    else {
        topWord = nil;
    }
}

- (void) setNeedsGenerateCloud
{
    @synchronized(self)
    {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(generateCloud) object:nil];
        [self performSelector:@selector(generateCloud) withObject:nil afterDelay:0.1f];
    }
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

-(CGFloat)fontSizeForOccuranceCount:(NSInteger)count usingFontSizeMode:(CPTWordFontSizeMode)fontSizeMode;
{
    CGFloat finalFontSize = 0.0f;
    switch (fontSizeMode) {
        case CPTWordFontSizeMode_rank: {
            // Use rank order to determine font size from min to max (relative difference in count between words doesn't effect sizing)
            NSSet *uniqueCountsInSortedWords = [NSSet setWithArray:[sortedWords valueForKeyPath:@"count"]];
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
                finalFontSize = roundf(self.minFontSize + (float)(self.maxFontSize-self.minFontSize)*(float)currentRank/((float)countOfRanks-1.0f));
            } else {
                finalFontSize = self.maxFontSize;
            }
        }   break;
        case CPTWordFontSizeMode_linearN: {
            // Use word frequency (count) to determine font sizing from min to max along a linear ramp
            CGFloat maxCount = (float)topWord.count;
            CGFloat minCount = (float)bottomWord.count;
            finalFontSize = self.minFontSize + ((self.maxFontSize - self.minFontSize) / (maxCount - minCount)) * (count-minCount);
        }   break;
        case CPTWordFontSizeMode_expN: {
            // Use word frequency (count) to determine font sizing from min to max based on an exponential ramp
            CGFloat maxCount = (float)topWord.count;
            CGFloat minCount = (float)bottomWord.count;
            CGFloat b = (1/(minCount-maxCount))*log10f((float)self.minFontSize/(float)self.maxFontSize);
            CGFloat a = (float)self.maxFontSize / powf(10,b * maxCount);
            finalFontSize = a * powf(10,b * (float)count);
        }   break;
        case CPTWordFontSizeMode_logN: {
            // Use word frequency (count) to determine font sizing from min to max based on an logarithmic ramp
            CGFloat maxCount = (float)topWord.count;
            CGFloat minCount = (float)bottomWord.count;
            CGFloat a = ((float)self.minFontSize - (float)self.maxFontSize)/(log10f(minCount)-log10f(maxCount));
            CGFloat b = powf(10, (float)self.minFontSize/a)/minCount;
            finalFontSize = a * log10f(b * (float)count);
        }   break;
        default:
            break;
    }

    return finalFontSize;
}

// sorts words if needed, and lays them out
- (void) generateCloud
{
    double scalingFactor = 1;
    double xShift = 0;
    double yShift = 0;
    
    [self filterAndSortWords];
    [self selectBoundaryWords];
    
    if (!wordCounts.count) {
        // No words in wordCloud, so pass empty array to the delegate
        if ([self.delegate respondsToSelector:@selector(wordCloudDidGenerateCloud:sortedWordArray:scalingFactor:xShift:yShift:)])
        {
            [self.delegate wordCloudDidGenerateCloud:self sortedWordArray:@[] scalingFactor:scalingFactor xShift:xShift yShift:yShift];
        }
        return;
    }
    
    if (!topWord) return;
    if (!topWord.count) return;
    if (true == CGSizeEqualToSize(self.cloudSize, CGSizeZero)) return;
    
    double step = 2;
    double aspectRatio = self.cloudSize.width / self.cloudSize.height;

    // prepare colors for interpolation
    float rColorPerOccurance = (highCountColorComponents[0] - lowCountColorComponents[0]) / topWord.count;
    float gColorPerOccurance = (highCountColorComponents[1] - lowCountColorComponents[1]) / topWord.count;
    float bColorPerOccurance = (highCountColorComponents[2] - lowCountColorComponents[2]) / topWord.count;
    float aColorPerOccurance = (highCountColorComponents[3] - lowCountColorComponents[3]) / topWord.count;

    // statistics for later calculation of scaling factor
    int minX = INT_MAX;
    int maxX = INT_MIN;
    int minY = INT_MAX;
    int maxY = INT_MIN;
    
    int wordLimit = self.maxNumberOfWords ? self.maxNumberOfWords : (int)sortedWords.count;
    for (int index=0; index < wordLimit; index++)
    {
        CPTWord* word = [sortedWords objectAtIndex:index];
        
        CGFloat fontSize = [self fontSizeForOccuranceCount:word.count usingFontSizeMode:self.fontSizeMode];
        if (self.isUsingRandomFontPerWord) {
            word.font = [self randomFontFromFontNames:self.selectableFontNames ofSize:fontSize];
        }
        else {
            word.font = [self.font fontWithSize:fontSize];
        }
                        
        word.color = [UIColor colorWithRed:lowCountColorComponents[0] + (rColorPerOccurance * word.count)
                                         green:lowCountColorComponents[1] + (gColorPerOccurance * word.count)
                                          blue:lowCountColorComponents[2] + (bColorPerOccurance * word.count)
                                         alpha:lowCountColorComponents[3] + (aColorPerOccurance * word.count)];
            
        NSDictionary *textAttributes = @{ NSFontAttributeName : word.font,
                                          NSForegroundColorAttributeName : word.color };
        //CGSize wordSize = [word.text sizeWithAttributes:textAttributes];

        CGSize wordSize = [word.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
                                                 options:(NSStringDrawingUsesDeviceMetrics | NSStringDrawingUsesFontLeading)
                                              attributes:textAttributes
                                                 context:nil].size;
        //NSLog(@"Word: %@; sizeWithAttr: %@; boundingRect: %@",word.text,NSStringFromCGSize(wordSize),NSStringFromCGSize(textRect.size));
        
        BOOL rotateWord = [self nextRandomBoolWithProbabilityForYes:self.probabilityOfWordVertical];
        word.rotated = rotateWord;

        if (word.rotated) {
            // Reverse dimensions for wordsize to simulate vertical drawing of text
            wordSize = CGSizeMake(wordSize.height, wordSize.width);
        }
        
        wordSize.height += (self.wordBorderSize.height * 2);
        wordSize.width += (self.wordBorderSize.width * 2);
        
        float horizCenter = (self.cloudSize.width - wordSize.width)/2;
        float vertCenter = (self.cloudSize.height - wordSize.height)/2;
        
//        word.bounds = CGRectMake(arc4random_uniform(10) + horizCenter, arc4random_uniform(10) + vertCenter, wordSize.width, wordSize.height);
        word.bounds = CGRectMake(horizCenter, vertCenter, wordSize.width, wordSize.height);

        //NSLog(@"Bounds for %@ word: %@ %@",word.isRotated ? @"ROTATED" : @"NONROTATED",word.text,NSStringFromCGRect(word.bounds));
        
        BOOL intersects = FALSE;
        double angleStep = (index % 2 == 0 ? 1 : -1) * step;
        double radius = 0;
        double angle = 10 * random();
        // move word until there are no collisions with previously placed words
        // adapted from https://github.com/lucaong/jQCloud
        do
        {
            for (int otherIndex=0; otherIndex < index; otherIndex++)
            {
                intersects = CGRectIntersectsRect(word.bounds, ((CPTWord*)[sortedWords objectAtIndex:otherIndex]).bounds);
                
                // if the current word intersects with word that has already been placed, move the current word, and
                // recheck against all already-placed words
                if (intersects)
                {
                    radius += step;
                    angle += angleStep;
                    
                    int xPos = horizCenter + (radius * cos(angle)) * aspectRatio;
                    int yPos = vertCenter + radius * sin(angle);
                    
                    word.bounds = CGRectMake(xPos, yPos, wordSize.width, wordSize.height);
                    
                    break;
                }
            }
        } while (intersects);
        
        if (minX > word.bounds.origin.x) minX = word.bounds.origin.x;
        if (minY > word.bounds.origin.y) minY = word.bounds.origin.y;
        if (maxX < word.bounds.origin.x + wordSize.width) maxX = word.bounds.origin.x + wordSize.width;
        if (maxY < word.bounds.origin.y + wordSize.height) maxY = word.bounds.origin.y + wordSize.height;
    }
        
    // scale down if necessary
    if (maxX - minX > self.cloudSize.width)
    {
        scalingFactor = self.cloudSize.width / (double)(maxX - minX);
        
        // if we are here, then words are larger than the view, and either minX is negative or maxX is larger than the width.
        // calculate the amount by which to shift all words so that they fit in the view.
        if (minX < 0) xShift = minX * scalingFactor * -1;
        else xShift = (self.cloudSize.width - maxX) * scalingFactor;
    }
    else if (maxX - minX < self.cloudSize.width) {
        scalingFactor = self.cloudSize.width / (double)(maxX - minX);
        xShift = minX * scalingFactor * - 1;
    }
    
    if (maxY - minY > self.cloudSize.height)
    {
        double newScalingFactor = self.cloudSize.height / (double)(maxY - minY);
        
        // if we've already scaled down in the X dimension, only apply the new scale if it is smaller
        if (scalingFactor < 1 && newScalingFactor < scalingFactor)
        {
            scalingFactor = newScalingFactor;
        }
        
        // if we are here, then words are larger than the view, and either minX is negative or maxX is larger than the width.
        // calculate the amount by which to shift all words so that they fit in the view.
        if (minY < 0) yShift = minY * scalingFactor * -1;
        else yShift = (self.cloudSize.height - maxY) * scalingFactor;
    }
    else if (maxY - minY < self.cloudSize.height) {
        double newScalingFactor = self.cloudSize.height / (double)(maxY - minY);
        if (scalingFactor > 1 && newScalingFactor < scalingFactor) {
            scalingFactor = newScalingFactor;
        }
        yShift = minY * scalingFactor * -1;
    }
    
    if ([self.delegate respondsToSelector:@selector(wordCloudDidGenerateCloud:sortedWordArray:scalingFactor:xShift:yShift:)])
    {
        [self.delegate wordCloudDidGenerateCloud:self sortedWordArray:sortedWords scalingFactor:scalingFactor xShift:xShift yShift:yShift];
    }
}

#pragma mark - accessors

- (void) setCloudSize:(CGSize)cloudSize
{
    if (true == CGSizeEqualToSize(cloudSize, self.cloudSize)) return;
    _cloudSize = cloudSize;
    
    [self setNeedsGenerateCloud];
}

- (void) setFont:(UIFont*)font
{
    if (font == self.font) return;    
    _font = font;
    
    [self setNeedsGenerateCloud];
}

- (void) setMinFontSize:(int)minFontSize
{
    if (minFontSize == self.minFontSize) return;
    _minFontSize = minFontSize;
    
    [self setNeedsGenerateCloud];
}

- (void) setMaxFontSize:(int)maxFontSize
{
    if (maxFontSize == self.maxFontSize) return;
    _maxFontSize = maxFontSize;
    
    [self setNeedsGenerateCloud];
}

- (void) setWordBorderSize:(CGSize)wordBorderSize
{
    if (CGSizeEqualToSize(wordBorderSize, _wordBorderSize)) return;
    _wordBorderSize = wordBorderSize;
    
    [self setNeedsGenerateCloud];
}

- (void) setLowCountColor:(UIColor*)color
{
    if (color == self.lowCountColor) return;
    _lowCountColor = color;
        
    CGColorRef colorRef = [self CGColorRefFromUIColor:color];
    const CGFloat* components = CGColorGetComponents(colorRef);
    lowCountColorComponents[0] = components[0];
    lowCountColorComponents[1] = components[1];
    lowCountColorComponents[2] = components[2];
    lowCountColorComponents[3] = CGColorGetAlpha(color.CGColor);
    CGColorRelease(colorRef);
    
    [self setNeedsGenerateCloud];
}

- (void) setHighCountColor:(UIColor*)color
{
    if (color == self.highCountColor) return;
    _highCountColor = color;
        
    CGColorRef colorRef = [self CGColorRefFromUIColor:color];
    const CGFloat* components = CGColorGetComponents(colorRef);
    highCountColorComponents[0] = components[0];
    highCountColorComponents[1] = components[1];
    highCountColorComponents[2] = components[2];
    highCountColorComponents[3] = CGColorGetAlpha(color.CGColor);
    CGColorRelease(colorRef);
    
    [self setNeedsGenerateCloud];
}

- (void) setMaxNumberOfWords:(int)maxNumberOfWords
{
    if (maxNumberOfWords == self.maxNumberOfWords) return;
    
    _maxFontSize = maxNumberOfWords;
    [self setNeedsGenerateCloud];
}


- (void) setMinimumWordLength:(int)minimumWordLength
{
    if (minimumWordLength == self.minimumWordLength) return;    
    _minimumWordLength = minimumWordLength;
    
    [self rebuild:[wordCounts.allKeys copy]];
}

-(void)setProbabilityOfWordVertical:(CGFloat)probabilityOfWordVertical;
{
    if (probabilityOfWordVertical != _probabilityOfWordVertical) {
        _probabilityOfWordVertical = probabilityOfWordVertical;
        [self setNeedsGenerateCloud];
    }
}

-(void)setUsingRandomFontPerWord:(BOOL)usingRandomFontPerWord;
{
    if (usingRandomFontPerWord != _usingRandomFontPerWord) {
        _usingRandomFontPerWord = usingRandomFontPerWord;
        [self setNeedsGenerateCloud];
    }
}

-(void)setSelectableFontNames:(NSArray *)selectableFontNames;
{
    if (selectableFontNames != _selectableFontNames) {
        _selectableFontNames = selectableFontNames;
        [self setNeedsGenerateCloud];
    }
}

-(void)setMinimumWordCountAllowed:(NSInteger)minimumWordCountAllowed;
{
    if (minimumWordCountAllowed != _minimumWordCountAllowed) {
        _minimumWordCountAllowed = minimumWordCountAllowed;
        [self setNeedsGenerateCloud];
    }
}

-(void)setConvertingAllWordsToLowercase:(BOOL)convertingAllWordsToLowercase;
{
    if (convertingAllWordsToLowercase != _convertingAllWordsToLowercase) {
        _convertingAllWordsToLowercase = convertingAllWordsToLowercase;
        [self setNeedsGenerateCloud];
    }
}

-(void)setFontSizeMode:(CPTWordFontSizeMode)fontSizeMode;
{
    if (fontSizeMode != _fontSizeMode) {
        _fontSizeMode = fontSizeMode;
        [self setNeedsGenerateCloud];
    }
}

-(void)setFilteringStopWords:(BOOL)filteringStopWords;
{
    if (filteringStopWords != _filteringStopWords) {
        _filteringStopWords = filteringStopWords;
        [self setNeedsGenerateCloud];
    }
}

#pragma mark - util

// hack to get the correct CGColors from ANY UIColor, even in a non-RGB color space (greyscale, etc)
// borrowed from http://stackoverflow.com/questions/4155642/how-to-get-color-components-of-a-cgcolor-correctly
- (CGColorRef) CGColorRefFromUIColor:(UIColor*)color
{
    CGFloat components[4] = {0.0, 0.0, 0.0, 0.0};
    [color getRed:&components[0] green:&components[1] blue:&components[2] alpha:&components[3]];
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGColorRef colorRef = CGColorCreate(colorSpaceRef, components);    
    CGColorSpaceRelease(colorSpaceRef);
    return colorRef;
}

@end
