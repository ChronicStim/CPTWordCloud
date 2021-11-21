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
#import <libkern/OSAtomic.h>

#import "CPTWordCloudView.h"

@interface CPTWordCloudView () 
{
    NSMutableDictionary* wordRects;    
    NSString* lastTouchedWord;
    
    UIColor* highlightColor;
    NSArray* highlightedWords;
}
@property (nonatomic, strong, readwrite) CPTWordCloud* wordCloud;

@end

@implementation CPTWordCloudView
@synthesize wordBackgroundColor = _wordBackgroundColor;

-(instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.wordCloud = [[CPTWordCloud alloc] init];
        self.wordCloud.cloudSize = frame.size;
        self.wordCloud.delegate = self;
        [self baseInit];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder;
{
    self = [super initWithCoder:coder];
    if (self) {
        self.wordCloud = [[CPTWordCloud alloc] init];
        self.wordCloud.cloudSize = self.bounds.size;
        self.wordCloud.delegate = self;
        [self baseInit];
    }
    return self;
}

- (void) baseInit
{
    self.layer.masksToBounds = TRUE;
    //self.layer.shouldRasterize = YES; // test
    
    self.backgroundColor = [UIColor clearColor];
    self.borderColor = [UIColor blackColor];
    self.borderWidth = 0.0f;
    self.cloudInsetMargins = UIEdgeInsetsMake(0, 20, 10, 10);
    
    _scalingFactor = 1;
}

- (id) initForWordCloud:(CPTWordCloud *)wordCloud;
{
    if (self = [super init])
    {
        if (nil == wordCloud) {
            wordCloud = [[CPTWordCloud alloc] init];
        }
        self.wordCloud = wordCloud;
        self.wordCloud.delegate = self;
        [self baseInit];
    }
    return self;
}

- (id) initForWordCloud:(CPTWordCloud *)wordCloud withFrame:(CGRect)frame;
{
    if (self = [super initWithFrame:frame])
    {
        if (nil == wordCloud) {
            wordCloud = [[CPTWordCloud alloc] init];
            wordCloud.cloudSize = frame.size;
        }
        self.wordCloud = wordCloud;
        self.wordCloud.delegate = self;
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

-(void)setCloudInsetMargins:(UIEdgeInsets)cloudInsetMargins;
{
    if (!UIEdgeInsetsEqualToEdgeInsets(cloudInsetMargins, _cloudInsetMargins)) {
        _cloudInsetMargins = cloudInsetMargins;
        self.wordCloud.cloudSize = UIEdgeInsetsInsetRect(self.bounds, _cloudInsetMargins).size;
    }
}

#pragma mark - view lifecycle

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (true == CGSizeEqualToSize(UIEdgeInsetsInsetRect(self.bounds, self.cloudInsetMargins).size, self.wordCloud.cloudSize)) return;
    self.wordCloud.cloudSize = UIEdgeInsetsInsetRect(self.bounds, self.cloudInsetMargins).size;
}

#pragma mark - CPTWordCloudDelegate

- (void) wordCloudDidGenerateCloud:(CPTWordCloud*)wc sortedWordArray:(NSArray*)words scalingFactor:(double)scalingFactor xShift:(double)xShift yShift:(double)yShift
{
    _words = words;
    _scalingFactor = scalingFactor;
    _xShift = xShift + self.cloudInsetMargins.left;
    _yShift = yShift + self.cloudInsetMargins.bottom;
    
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

-(UIColor *)wordBackgroundColor;
{
    if (nil != _wordBackgroundColor) {
        return _wordBackgroundColor;
    }
    
    _wordBackgroundColor = [UIColor clearColor];
    return _wordBackgroundColor;
}

-(void)setWordBackgroundColor:(UIColor *)wordBackgroundColor;
{
    if (wordBackgroundColor != _wordBackgroundColor) {
        _wordBackgroundColor = wordBackgroundColor;
        [self setNeedsDisplay];
    }
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
        
    CGContextTranslateCTM(c, 0, self.bounds.size.height);
    CGContextScaleCTM(c, 1, -1);
    
    CGContextClearRect(c, self.bounds);
    
    CGContextSetFillColorWithColor(c, self.backgroundColor.CGColor);
    CGContextFillRect(c, self.bounds);
    
    if (!self.words.count) return;
    
    for (CPTWord* word in self.words)
    {
        UIColor* color = [highlightedWords containsObject:word] ? highlightColor : word.color;
        UIColor *backColor = self.wordBackgroundColor;
        
        UIFont *font = [word.font fontWithSize:word.font.pointSize*self.scalingFactor];
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
            CGContextTranslateCTM(c, 0, -word.bounds.size.width * self.scalingFactor);
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

#pragma mark - Draw to external image

- (UIImage *)imageByRenderingView
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

-(NSData *)createPDFSaveToDocuments:(BOOL)saveToDocuments withFileName:(NSString*)aFilename;
{
    // Creates a mutable data object for updating with binary data, like a byte array
    NSMutableData *pdfData = [NSMutableData data];
    
    // Points the pdf converter to the mutable data object and to the UIView to be converted
    UIGraphicsBeginPDFContextToData(pdfData, self.bounds, nil);
    UIGraphicsBeginPDFPage();
    CGContextRef pdfContext = UIGraphicsGetCurrentContext();
    
    // draws rect to the view and thus this is captured by UIGraphicsBeginPDFContextToData
    [self.layer drawInContext:pdfContext];
    
    // remove PDF rendering context
    UIGraphicsEndPDFContext();
    
    if (saveToDocuments) {
        // Retrieves the document directories from the iOS device
        NSArray* documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,YES);
        
        NSString* documentDirectory = [documentDirectories objectAtIndex:0];
        NSString* documentDirectoryFilename = [documentDirectory stringByAppendingPathComponent:aFilename];
        
        // instructs the mutable data object to write its context to a file on disk
        [pdfData writeToFile:documentDirectoryFilename atomically:YES];
        NSLog(@"documentDirectoryFileName: %@",documentDirectoryFilename);
    }

    return [NSData dataWithData:pdfData];
}

-(void)drawInPDFContext:(CGContextRef)pdfContext;
{
    CGContextSaveGState(pdfContext);
    
    [self.layer drawInContext:pdfContext];
    
    CGContextRestoreGState(pdfContext);
}

@end
