//
//  CPTWordCloudSKView.m
//  CPTWordCloud
//
//  Created by Bob Kutschke on 12/17/21.
//

#import "CPTWordCloudSKView.h"
#import "CPTWordCloudSKScene.h"
#import <CoreText/CoreText.h>

@interface CPTWordCloudSKView ()

@property (nonatomic, strong, readwrite) CPTWordCloud* wordCloud;
@property (nonatomic, strong) CPTWordCloudSKScene *wordCloudSKScene;

@end

@implementation CPTWordCloudSKView

-(instancetype)initWithFrame:(CGRect)frame;
{
    if (self = [super initWithFrame:frame]) {
     
        [self startupSKViewDisplay];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder;
{
    if (self = [super initWithCoder:coder]) {
        
        [self startupSKViewDisplay];
    }
    return self;
}

-(void)startupSKViewDisplay;
{
    self.ignoresSiblingOrder = YES;

    // For Debugging
//    self.showsFPS = YES;
//    self.showsNodeCount = YES;

    self.wordCloud = [[CPTWordCloud alloc] init];
    self.wordCloud.cloudSize = self.frame.size;
    self.wordCloud.delegate = self;
    self.backgroundColor = [UIColor clearColor];
}

-(CPTWordCloudSKScene *)wordCloudSKScene;
{
    if (nil != _wordCloudSKScene) {
        return _wordCloudSKScene;
    }
    
    _wordCloudSKScene = [[CPTWordCloudSKScene alloc] initWordCloudSKSceneForWordCloud:self.wordCloud withSize:self.bounds.size];
    _wordCloudSKScene.scaleMode = SKSceneScaleModeAspectFit;
    [self presentScene:_wordCloudSKScene transition:[SKTransition fadeWithDuration:0.5]];
    
    return _wordCloudSKScene;
}

-(void)changeWordOutlineColor:(UIColor *)outlineColor;
{
    self.wordCloudSKScene.wordOutlineColor = outlineColor;
}

-(UIColor *)currentWordOutlineColor;
{
    return self.wordCloudSKScene.wordOutlineColor;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - view lifecycle

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (true == CGSizeEqualToSize(self.bounds.size, self.wordCloud.cloudSize)) return;
    self.wordCloud.cloudSize = self.bounds.size;
}

#pragma mark - CPTWordCloudDelegate

- (void)wordCloudDidRequestGenerationOfCloud:(CPTWordCloud *)wc withSortedWordArray:(NSArray *)words;
{
    [self.wordCloudSKScene generateSceneWithSortedWords:words];
}

#pragma mark - Drawing Code

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
    
    NSArray *words = [self.wordCloud sortedWords];
    
    if (!words.count) return;
    
    for (CPTWord* word in words)
    {
        UIColor* color = word.color;
        UIFont *font = [word.font fontWithSize:word.font.pointSize];
        NSDictionary *attrsDictionary = @{ NSFontAttributeName : font,
                                           NSForegroundColorAttributeName : color
        };
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:word.text attributes:attrsDictionary];
        CFAttributedStringRef cfAttrString  = (__bridge CFAttributedStringRef)attrString;
        
        CTLineRef line = CTLineCreateWithAttributedString(cfAttrString);
        
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        
        CGContextSaveGState(context);
        
        CGPoint scaledShiftedOrigin = CGPointMake((self.wordCloudSKScene.scalingFactor*word.wordOrigin.x)+(self.bounds.size.width/2.0f)+self.wordCloudSKScene.cloudOriginShift.x, (self.wordCloudSKScene.scalingFactor*word.wordOrigin.y)+(self.bounds.size.height/2.0f)+self.wordCloudSKScene.cloudOriginShift.y);
        
        CGContextTranslateCTM(context, scaledShiftedOrigin.x, scaledShiftedOrigin.y);
        if (!CGAffineTransformIsIdentity(word.rotationTransform)) {
            CGContextConcatCTM(context, word.rotationTransform);
        }
        CGContextScaleCTM(context, self.wordCloudSKScene.scalingFactor, self.wordCloudSKScene.scalingFactor);
        
        CTLineDraw(line, context);
        CFRelease(line);
        
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, scaledShiftedOrigin.x, scaledShiftedOrigin.y);
        if (!CGAffineTransformIsIdentity(word.rotationTransform)) {
            CGContextConcatCTM(context, word.rotationTransform);
        }
        CGContextScaleCTM(context, self.wordCloudSKScene.scalingFactor, self.wordCloudSKScene.scalingFactor);
        CGContextSetStrokeColorWithColor(context, self.wordCloudSKScene.wordOutlineColor.CGColor);
        CGContextStrokeRect(context, word.wordGlyphBounds);
        CGContextRestoreGState(context);
    }
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
