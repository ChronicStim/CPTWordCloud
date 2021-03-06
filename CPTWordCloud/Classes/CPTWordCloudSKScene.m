//
//  CPTWordCloudSKScene.m
//  CPTWordCloud
//
//  Created by Bob Kutschke on 12/17/21.
//

#import "CPTWordCloudSKScene.h"
#import "CPTWord.h"
#import "CPTWordCloud.h"
#import "CPTWordCloudSKView.h"
#import <CoreText/CoreText.h>

#define kCPTWordCloudWordCount @"kCPTWordCloudWordCount"

double lerp(double a, double b, double fraction) {
    return (b-a)*fraction + a;
}

@interface CPTWordCloudSKScene ()

@property (nonatomic) NSMutableArray *currentWordNodes;
@property (nonatomic) SKSpriteNode *cloudNode;
@property (nonatomic) SKShapeNode *unionNode;
@property (nonatomic, readwrite) CGFloat scalingFactor;
@property (nonatomic, readwrite) CGPoint cloudOriginShift;

@end

@implementation CPTWordCloudSKScene

-(instancetype)initWordCloudSKSceneForWordCloud:(CPTWordCloud *)wordCloud withSize:(CGSize)size;
{
    if (self = [super initWithSize:size]) {
        _wordCloud = wordCloud;
        _currentWordNodes = [NSMutableArray new];
        _wordOutlineColor = _wordCloud.wordOutlineColor;
    }
    return self;
}

-(BOOL)hasExistingNodes;
{
    return (0 < [self.currentWordNodes count]);
}

-(void)setWordCloud:(CPTWordCloud *)wordCloud;
{
    if (wordCloud != _wordCloud) {
        _wordCloud = wordCloud;
    }
}

-(void)setWordOutlineColor:(UIColor *)wordOutlineColor;
{
    if (wordOutlineColor != _wordOutlineColor) {
        _wordOutlineColor = wordOutlineColor;
        [self animateChangeWordOutlineColors];
    }
}

-(void)animateChangeWordOutlineColors;
{
    for (SKShapeNode *shapeNode in self.currentWordNodes) {
        
        SKColor *oldColor = shapeNode.strokeColor;
        SKColor *newColor = self.wordOutlineColor;
        
        [shapeNode runAction:[self getColorFadeActionFrom:oldColor toColor:newColor]];
    }
}

-(SKAction*)getColorFadeActionFrom:(SKColor*)col1 toColor:(SKColor*)col2 {
    
    // get the Color components of col1 and col2
    CGFloat r1 = 0.0, g1 = 0.0, b1 = 0.0, a1 =0.0;
    CGFloat r2 = 0.0, g2 = 0.0, b2 = 0.0, a2 =0.0;
    [col1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [col2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    // return a color fading on the fill color
    CGFloat timeToRun = 0.3;
    
    return [SKAction customActionWithDuration:timeToRun actionBlock:^(SKNode *node, CGFloat elapsedTime) {
        
        CGFloat fraction = elapsedTime / timeToRun;
        
        SKColor *col3 = [SKColor colorWithRed:lerp(r1,r2,fraction)
                                        green:lerp(g1,g2,fraction)
                                         blue:lerp(b1,b2,fraction)
                                        alpha:lerp(a1,a2,fraction)];
        
        [(SKShapeNode*)node setStrokeColor:col3];
    }];
}

-(void)didChangeSize:(CGSize)oldSize;
{
    self.wordCloud.cloudSize = self.size;
    
}

-(void)generateSceneWithSortedWords:(NSArray *)sortedWords;
{
    self.anchorPoint = CGPointMake(0.5, 0.5);
//    self.scaleMode = SKSceneScaleModeResizeFill;
    self.scaleMode = SKSceneScaleModeAspectFit;
    [self.cloudNode removeChildrenInArray:self.currentWordNodes];
    [self removeAllChildren];
    [self.currentWordNodes removeAllObjects];
    
    double step = 2;
    double aspectRatio = 1.0f;
    if (nil != self.wordCloud && !(0 == self.wordCloud.cloudSize.width || 0 == self.wordCloud.cloudSize.height)) {
        // Avoid any situation where we can end up with a zero or undefined aspectRatio
        aspectRatio = self.wordCloud.cloudSize.width / self.wordCloud.cloudSize.height;
    }
    
    CGRect unionRect = CGRectZero;
    
    self.cloudNode = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:CGSizeZero];
    self.cloudNode.anchorPoint = CGPointMake(0.5, 0.5);
    self.cloudNode.zPosition = 2;
    [self addChild:self.cloudNode];
    
    self.unionNode = [SKShapeNode shapeNodeWithRect:unionRect];
    [self.unionNode setStrokeColor:[UIColor clearColor]];
    [self.cloudNode addChild:self.unionNode];
    
    int wordLimit = (int)sortedWords.count;
    if (0 < self.wordCloud.maxNumberOfWords) {
        wordLimit = MIN((int)sortedWords.count, (int)self.wordCloud.maxNumberOfWords);
    }
    for (int index=0; index < wordLimit; index++)
    {
        CPTWord* word = [sortedWords objectAtIndex:index];

        CGFloat fontSize = [self.wordCloud fontSizeForOccuranceCount:word.count usingScalingMode:self.wordCloud.scalingMode];
        if (self.wordCloud.isUsingRandomFontPerWord) {
            word.font = [self.wordCloud randomFontFromFontNames:self.wordCloud.selectableFontNames ofSize:fontSize];
        }
        else {
            word.font = [self.wordCloud.font fontWithSize:fontSize];
        }
        
        if (0 >= word.count) {
            word.color = self.wordCloud.zeroCountColor;
        }
        else {
            word.color = [self.wordCloud wordColorForOccuranceCount:word.count usingScalingMode:self.wordCloud.scalingMode];
        }
        
        word.rotationAngle = [self.wordCloud getRotationAngleInRadiansForProbabilityOfRotation:self.wordCloud.probabilityOfWordRotation rotationMode:self.wordCloud.rotationMode];
        
        // Get line drawing size
        CGRect proposedWordFrame = CGRectZero;
        NSDictionary *textAttributes = @{ NSFontAttributeName : word.font,
                                          NSForegroundColorAttributeName : word.color };
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:word.text attributes:textAttributes];
        CFAttributedStringRef cfAttrString  = (__bridge CFAttributedStringRef)attrString;
        
        CTLineRef line = CTLineCreateWithAttributedString(cfAttrString);
        proposedWordFrame = CGRectIntegral(CGRectInset(CTLineGetImageBounds(line, NULL), -self.wordCloud.wordBorderSize.width*2, -self.wordCloud.wordBorderSize.height*2));
        CFRelease(line);
        
        // Store wordFrame with CPTWord object
        word.wordGlyphBounds = proposedWordFrame;

        // Build SKNode & SKLabel
        SKShapeNode *wordBorder = [SKShapeNode shapeNodeWithRect:proposedWordFrame];
        wordBorder.strokeColor = self.wordOutlineColor; // for debugging
        // Initially place in center of scene
        wordBorder.position = CGPointMake(roundf(-proposedWordFrame.size.width/2.0f), roundf(-proposedWordFrame.size.height/2.0f));
        wordBorder.zRotation = word.rotationAngle;
        wordBorder.name = word.text;
        wordBorder.userData = [NSMutableDictionary dictionaryWithDictionary:@{ kCPTWordCloudWordCount : @(word.count)}];

        SKLabelNode *wordLabel;
        wordLabel = [[SKLabelNode alloc] initWithFontNamed:word.font.fontName];
        wordLabel.text = word.text;
        wordLabel.fontSize = word.font.pointSize;
        wordLabel.fontColor = word.color;
        wordLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        wordLabel.name = word.text;
        [wordBorder addChild:wordLabel];
        
        [self.unionNode addChild:wordBorder];

        BOOL intersects = FALSE;
        double angleStep = (index % 2 == 0 ? 1 : -1) * step;
        double radius = 0;
        double angle = 10 * random();
        
        do
        {
            for (int otherIndex=0; otherIndex < index; otherIndex++)
            {
                SKShapeNode *otherShapeNode = [self.currentWordNodes objectAtIndex:otherIndex];
                intersects = [wordBorder intersectsNode:otherShapeNode];
                
                // if the current word intersects with word that has already been placed, move the current word, and
                // recheck against all already-placed words
                if (intersects)
                {
                    radius += step;
                    angle += angleStep;
                    
                    if ((CGFLOAT_MIN >= radius || CGFLOAT_MAX <= radius) || (CGFLOAT_MIN >= angle || CGFLOAT_MAX <= angle)) {
                        // If limits are exceeded, start the process over
                        radius = 0;
                        angle = 10 * random();
                    }
                    
                    CGFloat xPos = roundf(wordBorder.position.x + (radius * cos(angle)) * aspectRatio);
                    CGFloat yPos = roundf(wordBorder.position.y + radius * sin(angle));
                    
                    wordBorder.position = CGPointMake(xPos, yPos);
                    break;
                }
            }
        } while (intersects);
        
        // Store the position & rotation info with the word object
        word.wordOrigin = wordBorder.position;
        word.rotationAngle = wordBorder.zRotation;
        word.rotationTransform = CGAffineTransformMakeRotation(word.rotationAngle);
        
        // Debugging log statement
        //NSLog(@"wordOrigin: (%.f,%.f); rotationAngle: %.f;",word.wordOrigin.x,word.wordOrigin.y,word.rotationAngle);
        
        // Store the shapeNode to the scene's collection
        [self.currentWordNodes addObject:wordBorder];
        
        // Update the unionNode tracking size of the cloud
        unionRect = CGRectIntegral(CGRectUnion(unionRect,[wordBorder calculateAccumulatedFrame]));
    }
    CGPathRef unionRectPath = CGPathCreateWithRect(unionRect, NULL);
    [self.unionNode setPath:unionRectPath];
    CGPathRelease(unionRectPath);

    // Use the unionNode to resize cloudNode to fit placement of shapeNodes
    CGFloat unionRectAR = unionRect.size.width / unionRect.size.height;
    CGPoint unionCenter = CGPointMake(CGRectGetMidX(unionRect), CGRectGetMidY(unionRect));
    CGSize cloudNodeNewSize;
    if (unionRectAR > aspectRatio) {
        // Dominant width
        cloudNodeNewSize = CGSizeMake(unionRect.size.width, unionRect.size.width / aspectRatio);
        self.scalingFactor = self.wordCloud.cloudSize.width / unionRect.size.width;
    }
    else {
        // Dominant Height
        cloudNodeNewSize = CGSizeMake(unionRect.size.height * aspectRatio, unionRect.size.height);
        self.scalingFactor = self.wordCloud.cloudSize.height / unionRect.size.height;
    }

    self.cloudNode.size = cloudNodeNewSize;
    [self.cloudNode setScale:self.scalingFactor];
    
    
    // Finally, recenter the unionNode to align the wordCloud
    self.cloudOriginShift = CGPointMake(-unionCenter.x, -unionCenter.y);
    self.unionNode.position = self.cloudOriginShift;
}

-(void)updateExistingScene;
{
    // Use existing SKNodes and only change aspects that don't effect size/position (e.g. color)
    CGRect unionRect = CGRectZero;
    for (SKShapeNode *shapeNode in self.currentWordNodes) {
        
        shapeNode.strokeColor = self.wordOutlineColor;
        SKLabelNode *labelNode = (SKLabelNode *)[shapeNode childNodeWithName:shapeNode.name];
        NSInteger wordCount = (NSInteger)[[shapeNode.userData objectForKey:kCPTWordCloudWordCount] integerValue];
        
        if (0 >= wordCount) {
            labelNode.fontColor = self.wordCloud.zeroCountColor;
        }
        else {
            labelNode.fontColor = [self.wordCloud wordColorForOccuranceCount:wordCount usingScalingMode:self.wordCloud.scalingMode];
        }
        
        // Update the unionNode tracking size of the cloud
        unionRect = CGRectUnion(unionRect,[shapeNode calculateAccumulatedFrame]);
    }

    // Use the unionNode to resize cloudNode to fit placement of shapeNodes
    double aspectRatio = self.wordCloud.cloudSize.width / self.wordCloud.cloudSize.height;
    CGFloat unionRectAR = unionRect.size.width / unionRect.size.height;
    CGPoint unionCenter = CGPointMake(CGRectGetMidX(unionRect), CGRectGetMidY(unionRect));
    CGSize cloudNodeNewSize;
    if (unionRectAR > aspectRatio) {
        // Dominant width
        cloudNodeNewSize = CGSizeMake(unionRect.size.width, unionRect.size.width / aspectRatio);
        self.scalingFactor = self.wordCloud.cloudSize.width / unionRect.size.width;
    }
    else {
        // Dominant Height
        cloudNodeNewSize = CGSizeMake(unionRect.size.height * aspectRatio, unionRect.size.height);
        self.scalingFactor = self.wordCloud.cloudSize.height / unionRect.size.height;
    }
    
    // Reset the cloudNode values before setting the new ones
    self.cloudNode.size = CGSizeZero;
    [self.cloudNode setScale:1.0f];
    
    self.cloudNode.size = cloudNodeNewSize;
    [self.cloudNode setScale:self.scalingFactor];
    
    // Finally, recenter the unionNode to align the wordCloud
    self.cloudOriginShift = CGPointMake(-unionCenter.x, -unionCenter.y);
    self.unionNode.position = self.cloudOriginShift;
}

@end
