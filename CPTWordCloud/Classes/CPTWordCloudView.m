//
//  CPTWordCloudView.m
//  CPTWordCloud
//
//  Created by Bob Kutschke on 1/5/22.
//

#import "CPTWordCloudView.h"
#import "CPTWordCloudSKView.h"
#import "CPTWordCloudSKScene.h"

@interface CPTWordCloudView ()
{
    CGSize _cloudSize;
}
@property (nonatomic, strong) UIView *rootView;
@property (weak, nonatomic) IBOutlet UIView *outerContainmentView;
@property (weak, nonatomic) IBOutlet UIStackView *verticalStackView;
@property (weak, nonatomic) IBOutlet UIView *titleContainmentView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *cloudContainmentView;
@property (weak, nonatomic) IBOutlet UIView *cloudBorderView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudSKViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudSKViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudBorderViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cloudBorderViewHeightConstraint;

@end

IB_DESIGNABLE
@implementation CPTWordCloudView

-(instancetype)initWithFrame:(CGRect)frame;
{
    self = [super initWithFrame:frame];
    if (self) {
        [self xibSetup];
        [self setupViewDefaults];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder;
{
    self = [super initWithCoder:coder];
    if (self) {
        [self xibSetup];
        [self setupViewDefaults];
    }
    return self;
}

-(void)xibSetup;
{
    if (nil != _rootView) {
        return;
    }
    
    _rootView = [self loadViewFromNib];
    _rootView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_rootView];
    [_rootView.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [_rootView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    [_rootView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor].active = YES;
    [_rootView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor].active = YES;
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

-(UIView *)loadViewFromNib;
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:bundle];
    UIView *view = [[nib instantiateWithOwner:self options:nil] objectAtIndex:0];
    return view;
}

-(void)prepareForInterfaceBuilder;
{
    [super prepareForInterfaceBuilder];

    // Add a default CPTWordCloud to view to provide some data to display
    {
       CPTWordCloud *ibWordCloud = [[CPTWordCloud alloc] init];
        ibWordCloud.lowCountColor = [UIColor colorWithRed:0.022 green:0.000 blue:0.751 alpha:1.000];
        ibWordCloud.highCountColor = [UIColor colorWithRed:0.751 green:0.000 blue:0.052 alpha:1.000];
        
        ibWordCloud.scalingMode = CPTWordScalingMode_rank;
        
        ibWordCloud.probabilityOfWordRotation = 0.8f;
        ibWordCloud.rotationMode = CPTWordRotationMode_Deg30;
        
        ibWordCloud.usingRandomFontPerWord = NO;
        
        ibWordCloud.convertingAllWordsToLowercase = YES;
        
        [ibWordCloud addWords:@"Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, `and what is the use of a book,' thought Alice `without pictures or conversation?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her. There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, `Oh dear! Oh dear! I shall be late!' (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural); but when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran across the field after it, and fortunately was just in time to see it pop down a large rabbit-hole under the hedge." delimiter:@" "];
        [self assignWordCloud:ibWordCloud];
    }
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
    
//    self.wordCloud.cloudSize = self.bounds.size;
//    self.wordCloud.wordCloudSKScene.size = self.bounds.size;
//    self.wordCloud.colorMappingHSBBased = YES;
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

-(void)adjustCloudViewSizingConstraints;
{
    CGFloat borderWidth = ceilf(self.bounds.size.width * self.borderWidthAsPercentOfViewWidth / 100.0f);
    self.cloudBorderViewWidthConstraint.constant = -(borderWidth);
    self.cloudBorderViewHeightConstraint.constant = -(borderWidth);
    CGFloat widthInset = ceilf(self.bounds.size.width * self.wordCloudInsetsFromBorderAsPercentOfViewWidth.width / 100.0f);
    CGFloat heightInset = ceilf(self.bounds.size.width * self.wordCloudInsetsFromBorderAsPercentOfViewWidth.height / 100.0f);
    CGFloat cloudWidthConst = -((borderWidth + widthInset) * 2);
    CGFloat cloudHeightConst = -((borderWidth + heightInset) * 2);
    self.cloudSKViewWidthConstraint.constant = cloudWidthConst;
    self.cloudSKViewHeightConstraint.constant = cloudHeightConst;
    
    CGSize targetCloudSize = CGSizeMake(self.bounds.size.width+cloudWidthConst, self.bounds.size.height+cloudHeightConst);
    self.wordCloud.cloudSize = targetCloudSize;
}

-(void)updateConstraints;
{
    [self adjustCloudViewSizingConstraints];
    
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

-(void)assignWordCloud:(CPTWordCloud *)wordCloud;
{
    if (nil != wordCloud) {
        wordCloud.wordCloudSKScene.backgroundColor = self.cloudAreaBackgroundColor;
    }
    [self.wordCloudSKView assignWordCloud:wordCloud];
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
        self.wordCloud.wordCloudSKScene.backgroundColor = cloudAreaBackgroundColor;
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

-(CGSize)autoLayoutCalculatedWordCloudSKViewSize;
{
    return self.wordCloudSKView.bounds.size;
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
