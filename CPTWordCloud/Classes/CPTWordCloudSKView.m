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

@end

IB_DESIGNABLE
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

-(void)prepareForInterfaceBuilder;
{
    [super prepareForInterfaceBuilder];
 
    if (nil != self.wordCloud) {
        self.wordCloud.cloudSize = self.bounds.size;
        [self.wordCloud updateCloudSceneWithRegenerateNodes:@(NO)];
    }
}

-(void)assignWordCloud:(CPTWordCloud *)wordCloud;
{
    self.wordCloud = wordCloud;
    [self.wordCloud updateCloudSceneWithRegenerateNodes:@(NO)];
}

-(void)startupSKViewDisplay;
{
    self.ignoresSiblingOrder = YES;

    // For Debugging
//    self.showsFPS = YES;
//    self.showsNodeCount = YES;

    self.backgroundColor = [UIColor clearColor];
}

-(void)setWordCloud:(CPTWordCloud *)wordCloud;
{
    if (wordCloud != _wordCloud) {
        _wordCloud = wordCloud;
    }
    _wordCloud.delegate = self;
    _wordCloud.cloudSize = self.frame.size;
    [_wordCloud wordCloudHasBeenAddedToSKView];
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

- (void)wordCloud:(CPTWordCloud *)wc readyToPresentScene:(CPTWordCloudSKScene *)scene;
{
    [self presentScene:scene transition:[SKTransition fadeWithDuration:0.25]];
}

#pragma mark - Drawing Code

- (void) drawRect:(CGRect)rect
{
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    [self drawWordCloudInContext:c];
}

-(void)drawWordCloudInContext:(CGContextRef)context;
{
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1, -1);
    
    NSArray *words = [self.wordCloud sortedWords];
    
    if (!words.count) return;
    
    for (CPTWord* word in words)
    {
        CGContextSaveGState(context);
        
        UIColor* color = word.color;
        UIFont *font = [word.font fontWithSize:word.font.pointSize];
        NSDictionary *attrsDictionary = @{ NSFontAttributeName : font,
                                           NSForegroundColorAttributeName : color
        };
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:word.text attributes:attrsDictionary];
        CFAttributedStringRef cfAttrString  = (__bridge CFAttributedStringRef)attrString;
        
        CTLineRef line = CTLineCreateWithAttributedString(cfAttrString);
        
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        
        CGFloat scalingFactor = self.wordCloud.wordCloudSKScene.scalingFactor;
        
        CGPoint scaledShiftedOrigin = CGPointMake((scalingFactor*word.wordOrigin.x)+(self.bounds.size.width/2.0f)+(scalingFactor*self.wordCloud.wordCloudSKScene.cloudOriginShift.x), (scalingFactor*word.wordOrigin.y)+(self.bounds.size.height/2.0f)+(scalingFactor*self.wordCloud.wordCloudSKScene.cloudOriginShift.y));
        
        CGContextTranslateCTM(context, scaledShiftedOrigin.x, scaledShiftedOrigin.y);
        if (!CGAffineTransformIsIdentity(word.rotationTransform)) {
            CGContextConcatCTM(context, word.rotationTransform);
        }
        CGContextScaleCTM(context, self.wordCloud.wordCloudSKScene.scalingFactor, self.wordCloud.wordCloudSKScene.scalingFactor);
        
        CTLineDraw(line, context);
        CFRelease(line);
        
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        CGContextTranslateCTM(context, scaledShiftedOrigin.x, scaledShiftedOrigin.y);
        if (!CGAffineTransformIsIdentity(word.rotationTransform)) {
            CGContextConcatCTM(context, word.rotationTransform);
        }
        CGContextScaleCTM(context, self.wordCloud.wordCloudSKScene.scalingFactor, self.wordCloud.wordCloudSKScene.scalingFactor);
        CGContextSetStrokeColorWithColor(context, self.wordCloud.wordCloudSKScene.wordOutlineColor.CGColor);
        CGContextStrokeRect(context, word.wordGlyphBounds);
        CGContextRestoreGState(context);
    }

    CGContextRestoreGState(context);
}

#pragma mark - Draw to external image

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

@end
