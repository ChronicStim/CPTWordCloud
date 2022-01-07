//
//  CPTWordCloudView.m
//  CPTWordCloud
//
//  Created by Bob Kutschke on 1/5/22.
//

#import "CPTWordCloudView.h"
#import "CPTWordCloudSKView.h"

@interface CPTWordCloudView ()
{
    CGSize _cloudSize;
}

@property (weak, nonatomic) IBOutlet UIView *outerContainmentView;
@property (weak, nonatomic) IBOutlet UIStackView *verticalStackView;
@property (weak, nonatomic) IBOutlet UIView *titleContainmentView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *cloudContainmentView;
@property (weak, nonatomic) IBOutlet UIView *cloudBorderView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudBorderViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudBorderViewHeightConstraint;

@end

@implementation CPTWordCloudView

-(instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self setupViewDefaults];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder;
{
    self = [super initWithCoder:coder];
    if (self) {
        
        [self setupViewDefaults];
    }
    return self;
}

-(void)setupViewDefaults;
{
    _cloudSize = CGSizeZero;
    self.borderWidthAsPercentOfViewWidth = 1.0f;
    self.borderColor = [UIColor blackColor];
    self.cornerRadiusAsPercentOfViewWidth = 5.0f;
    self.cloudAreaBackgroundColor = [UIColor whiteColor];
    self.titleColor = [UIColor blackColor];
    self.titleFont = [UIFont boldSystemFontOfSize:34];
    self.titleString = @"Sample Word Cloud Title";
    self.wordCloudInsetsFromBorderAsPercentOfViewWidth = CGSizeMake(5, 5);
    
}

-(void)updateConstraints;
{
    CGFloat borderWidth = ceilf(self.bounds.size.width * self.borderWidthAsPercentOfViewWidth / 100.0f);
    self.cloudBorderViewWidthConstraint.constant = -(borderWidth * 2);
    self.cloudBorderViewHeightConstraint.constant = -(borderWidth * 2);
    CGFloat widthInset = ceilf(self.bounds.size.width * self.wordCloudInsetsFromBorderAsPercentOfViewWidth.width / 100.0f);
    CGFloat heightInset = ceilf(self.bounds.size.width * self.wordCloudInsetsFromBorderAsPercentOfViewWidth.height / 100.0f);
    self.cloudViewWidthConstraint.constant = -((2 * borderWidth + widthInset) * 2);
    self.cloudViewHeightConstraint.constant = -((2 * borderWidth + heightInset) * 2);
    
    [super updateConstraints];
}

- (void)updateCloudViewFeatures;
{
    self.cloudBorderView.layer.borderWidth = self.bounds.size.width * self.borderWidthAsPercentOfViewWidth/100.0f;
    self.cloudBorderView.layer.borderColor = self.borderColor.CGColor;
    self.cloudBorderView.layer.cornerRadius = self.bounds.size.width * self.cornerRadiusAsPercentOfViewWidth / 100.0f;
    self.cloudBorderView.backgroundColor = self.cloudAreaBackgroundColor;
    
    self.titleLabel.textColor = self.titleColor;
    
    CGFloat fontSize = [self fontSizeForString:self.titleString toFitSize:self.titleLabel.bounds.size withFont:self.titleFont minFontScale:0.1 maxFontSize:60 lineBreakMode:NSLineBreakByClipping alignment:NSTextAlignmentCenter];
    self.titleLabel.font = [self.titleFont fontWithSize:fontSize];
    self.titleLabel.text = self.titleString;
}

-(void)setBorderWidthAsPercentOfViewWidth:(CGFloat)borderWidthAsPercentOfViewWidth;
{
    if (borderWidthAsPercentOfViewWidth != _borderWidthAsPercentOfViewWidth) {
        _borderWidthAsPercentOfViewWidth = borderWidthAsPercentOfViewWidth;
        [self setNeedsDisplay];
    }
}

-(void)setBorderColor:(UIColor *)borderColor;
{
    if (borderColor != _borderColor) {
        _borderColor = borderColor;
        [self setNeedsDisplay];
    }
}

-(void)setCornerRadiusAsPercentOfViewWidth:(CGFloat)cornerRadiusAsPercentOfViewWidth;
{
    if (cornerRadiusAsPercentOfViewWidth != _cornerRadiusAsPercentOfViewWidth) {
        _cornerRadiusAsPercentOfViewWidth = cornerRadiusAsPercentOfViewWidth;
        [self setNeedsDisplay];
    }
}

-(void)setCloudAreaBackgroundColor:(UIColor *)cloudAreaBackgroundColor;
{
    if (cloudAreaBackgroundColor != _cloudAreaBackgroundColor) {
        _cloudAreaBackgroundColor = cloudAreaBackgroundColor;
        [self setNeedsDisplay];
    }
}

-(void)setTitleColor:(UIColor *)titleColor;
{
    if (titleColor != _titleColor) {
        _titleColor = titleColor;
        [self setNeedsDisplay];
    }
}

-(void)setTitleFont:(UIFont *)titleFont;
{
    if (titleFont != _titleFont) {
        _titleFont = titleFont;
        [self setNeedsDisplay];
    }
}

-(void)setTitleString:(NSString *)titleString;
{
    if (titleString != _titleString) {
        _titleString = titleString;
        [self setNeedsDisplay];
    }
}

-(void)setWordCloudInsetsFromBorderAsPercentOfViewWidth:(CGSize)wordCloudInsetsFromBorderAsPercentOfViewWidth;
{
    if (!CGSizeEqualToSize(wordCloudInsetsFromBorderAsPercentOfViewWidth, _wordCloudInsetsFromBorderAsPercentOfViewWidth)) {
        _wordCloudInsetsFromBorderAsPercentOfViewWidth = wordCloudInsetsFromBorderAsPercentOfViewWidth;
        [self setNeedsUpdateConstraints];
    }
}

-(CGFloat)fontSizeForString:(NSString *)string toFitSize:(CGSize)boxSize withFont:(UIFont *)font minFontScale:(CGFloat)minFontScale maxFontSize:(CGFloat)maxFontSize lineBreakMode:(NSLineBreakMode)lineBreakMode alignment:(NSTextAlignment)alignment;
{
    if (0 >= minFontScale) {
        minFontScale = 0.5f;
    }
    CGFloat testFontSize = floor(maxFontSize * minFontScale);
    CGFloat finalFontSize = testFontSize;
    CGRect targetRect = CGRectMake(0, 0, boxSize.width, boxSize.height);
    CGRect currentRect;
    UIFont *testFont;
    NSAttributedString *attrString;
    
    NSMutableParagraphStyle* paragraphStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
    paragraphStyle.lineBreakMode = lineBreakMode;
    paragraphStyle.alignment = alignment;
    NSDictionary* attributes;
    
    BOOL continueProcessing = YES;
    while (continueProcessing) {
        finalFontSize = testFontSize;
        if (finalFontSize >= maxFontSize) {
            return maxFontSize;
        }
        testFontSize += 1.0f;
        if (testFontSize >= maxFontSize) {
            testFontSize = maxFontSize;
        }
        testFont = [font fontWithSize:testFontSize];
        
        attributes = @{NSFontAttributeName: testFont, NSParagraphStyleAttributeName: paragraphStyle};
        
        attrString = [[NSAttributedString alloc] initWithString:string attributes:attributes];
        
        currentRect = [attrString boundingRectWithSize:targetRect.size options:NSStringDrawingUsesLineFragmentOrigin context:nil];
        
        continueProcessing = CGRectContainsRect(targetRect, currentRect);
    }

    return finalFontSize;
}

#pragma mark - Drawing methods

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

- (void) drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    [self updateCloudViewFeatures];
    [self drawWordCloudInContext:c];
}

-(void)drawWordCloudInContext:(CGContextRef)context;
{
    CGContextSaveGState(context);

    CGRect titleFrame = [self.titleLabel convertRect:self.titleLabel.frame toView:self];
    CGContextTranslateCTM(context, titleFrame.origin.x, titleFrame.origin.y);
    [self.titleLabel.layer drawInContext:context];
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);

    CGRect cloudContainmentFrame = [self convertRect:self.cloudContainmentView.frame fromView:self.verticalStackView];
    CGContextTranslateCTM(context, cloudContainmentFrame.origin.x, cloudContainmentFrame.origin.y);
    CGFloat cornerRadius = self.bounds.size.width * self.cornerRadiusAsPercentOfViewWidth / 100.0f;
    CGPathRef rectPath = CGPathCreateWithRoundedRect(self.cloudBorderView.frame, cornerRadius, cornerRadius, nil);
    
    CGContextAddPath(context, rectPath);
    CGContextSetFillColorWithColor(context, self.cloudAreaBackgroundColor.CGColor);
    CGContextDrawPath(context, kCGPathFill);
    CGContextAddPath(context, rectPath);
    CGContextSetStrokeColorWithColor(context, self.borderColor.CGColor);
    CGContextSetLineWidth(context, self.bounds.size.width * self.borderWidthAsPercentOfViewWidth / 100.0f);
    CGContextDrawPath(context, kCGPathStroke);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);

    CGRect cloudRect = [self convertRect:self.wordCloudSKView.frame fromView:self.cloudBorderView];
    CGContextTranslateCTM(context, cloudRect.origin.x, cloudRect.origin.y);
    
    [self.wordCloudSKView drawWordCloudInContext:context];
    CGContextRestoreGState(context);
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

@end
