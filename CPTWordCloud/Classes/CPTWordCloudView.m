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
@synthesize wordOutlineColor = _wordOutlineColor;

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
    CGAffineTransform scalingTransform = CGAffineTransformMakeScale(scalingFactor, scalingFactor);
    
    wordRects = [[NSMutableDictionary alloc] initWithCapacity:self.words.count];
    for (CPTWord* word in self.words)
    {
        word.scalingTransform = scalingTransform;
        CGPoint scaledWordOrigin = [word wordOriginWithScaling:YES];
        word.wordOrigin = CGPointMake(scaledWordOrigin.x+self.xShift, scaledWordOrigin.y+self.yShift);
        CGRect wordRect = [word wordRectForCurrentOriginWithScaling:YES];
        [wordRects setObject:[NSValue valueWithCGRect:wordRect] forKey:word.text];
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

-(UIColor *)wordOutlineColor;
{
    if (nil != _wordOutlineColor) {
        return _wordOutlineColor;
    }
    
    _wordOutlineColor = [UIColor clearColor];
    return _wordOutlineColor;
}

-(void)setWordOutlineColor:(UIColor *)wordBackgroundColor;
{
    if (wordBackgroundColor != _wordOutlineColor) {
        _wordOutlineColor = wordBackgroundColor;
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
        
    [self drawWordCloudInContext:c];
}

-(void)drawWordCloudInContext:(CGContextRef)context;
{
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    CGContextClearRect(context, self.bounds);
    
    CGContextSetFillColorWithColor(context, self.backgroundColor.CGColor);
    CGContextFillRect(context, self.bounds);

    if (!self.words.count) return;
    
    for (CPTWord* word in self.words)
    {
        UIColor* color = [highlightedWords containsObject:word] ? highlightColor : word.color;
        
        NSValue *wordRectValue = [wordRects objectForKey:word.text];
        CGRect wordRect = wordRectValue.CGRectValue;

        UIFont *font = [word.font fontWithSize:word.font.pointSize];
        NSDictionary *attrsDictionary = @{ NSFontAttributeName : font,
                                           NSForegroundColorAttributeName : color
        };
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:word.text attributes:attrsDictionary];
        CFAttributedStringRef cfAttrString  = (__bridge CFAttributedStringRef)attrString;
        
        CTLineRef line = CTLineCreateWithAttributedString(cfAttrString);
        
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        
        CGContextSaveGState(context);
        
        CGContextTranslateCTM(context, word.wordOrigin.x, word.wordOrigin.y);
        if (word.isRotated) {
            CGContextRotateCTM(context, M_PI / 2.0f);
        }
        CGContextScaleCTM(context, self.scalingFactor, self.scalingFactor);
        
        
        CTLineDraw(line, context);
        CFRelease(line);
        
        CGContextRestoreGState(context);

        CGContextSaveGState(context);
        
        CGContextSetStrokeColorWithColor(context, self.wordOutlineColor.CGColor);
        CGContextStrokeRect(context, wordRect);

        CGContextRestoreGState(context);
        
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

- (UIImage *)imageByRenderingView;
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage * snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshotImage;
}

-(UIImage *)imageByDrawingView;
{
    UIImage __block *graphImageCapture = nil;

    if ([NSThread isMainThread])
    {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
        CGContextRef c = UIGraphicsGetCurrentContext();
        
        [self drawWordCloudInContext:c];
        
        graphImageCapture = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    else
    {
        __weak __typeof__(self) weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            __typeof__(self) strongSelf = weakSelf;
            graphImageCapture = [strongSelf imageByDrawingView];
        });
    }
    
    return graphImageCapture;
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
