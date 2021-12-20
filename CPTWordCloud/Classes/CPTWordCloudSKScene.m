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

double lerp(double a, double b, double fraction) {
    return (b-a)*fraction + a;
}

@interface CPTWordCloudSKScene ()

@property (nonatomic) NSMutableArray *currentWordNodes;
@property (nonatomic) SKSpriteNode *cloudNode;

@end

@implementation CPTWordCloudSKScene

-(instancetype)initWordCloudSKSceneForWordCloud:(CPTWordCloud *)wordCloud withSize:(CGSize)size;
{
    if (self = [super initWithSize:size]) {
        self.wordCloud = wordCloud;
        self.currentWordNodes = [NSMutableArray new];
        _wordOutlineColor = [UIColor clearColor];
    }
    return self;
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
    self.scaleMode = SKSceneScaleModeAspectFit;
    [self.cloudNode removeChildrenInArray:self.currentWordNodes];
    [self removeAllChildren];
    [self.currentWordNodes removeAllObjects];
    
    double step = 2;
    double aspectRatio = self.wordCloud.cloudSize.width / self.wordCloud.cloudSize.height;
    CGRect unionRect = CGRectZero;
    
    self.cloudNode = [SKSpriteNode spriteNodeWithColor:[UIColor whiteColor] size:CGSizeZero];
    self.cloudNode.anchorPoint = CGPointMake(0.5, 0.5);
    [self addChild:self.cloudNode];
    
    SKShapeNode *unionNode = [SKShapeNode shapeNodeWithRect:unionRect];
    [unionNode setStrokeColor:[UIColor greenColor]];
    [self.cloudNode addChild:unionNode];
    
    int wordLimit = self.wordCloud.maxNumberOfWords ? self.wordCloud.maxNumberOfWords : (int)sortedWords.count;
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
        proposedWordFrame = CGRectInset(CTLineGetImageBounds(line, NULL), -self.wordCloud.wordBorderSize.width*2, -self.wordCloud.wordBorderSize.height*2);

        // Build SKNode & SKLabel
        SKShapeNode *wordBorder = [SKShapeNode shapeNodeWithRect:proposedWordFrame];
        wordBorder.strokeColor = self.wordOutlineColor; // for debugging
        // Initially place in center of scene
        wordBorder.position = CGPointMake(-proposedWordFrame.size.width/2.0f, -proposedWordFrame.size.height/2.0f);
        wordBorder.zRotation = word.rotationAngle;
        wordBorder.name = word.text;
        
        SKLabelNode *wordLabel;
        if (@available(iOS 11.0, *)) {
            wordLabel = [SKLabelNode labelNodeWithAttributedText:attrString];
        } else {
            // Fallback on earlier versions
            wordLabel = [[SKLabelNode alloc] initWithFontNamed:word.font.fontName];
            wordLabel.text = word.text;
            wordLabel.fontSize = word.font.pointSize;
            wordLabel.fontColor = word.color;
        }
        wordLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        //wordLabel.position = CGPointMake(wordBorder.frame.size.width/2.0f, 0);
        wordLabel.name = word.text;
        [wordBorder addChild:wordLabel];
        
        [self.cloudNode addChild:wordBorder];

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
                    
                    int xPos = wordBorder.position.x + (radius * cos(angle)) * aspectRatio;
                    int yPos = wordBorder.position.y + radius * sin(angle);
                    
                    wordBorder.position = CGPointMake(xPos, yPos);
                    break;
                }
            }
        } while (intersects);
        
        [self.currentWordNodes addObject:wordBorder];
        unionRect = CGRectUnion(unionRect,[wordBorder calculateAccumulatedFrame]);
        //[unionNode setPosition:CGPointMake(unionRect.origin.x, unionRect.origin.y)];
        [unionNode setPath:CGPathCreateWithRect(unionRect, NULL)];
       // NSLog(@"UnionRect = %@", NSStringFromCGRect(unionRect));
    }
    
    // Resize cloudNode to fit placement of shapeNodes
    CGFloat unionRectAR = unionRect.size.width / unionRect.size.height;
    CGPoint unionCenter = CGPointMake(CGRectGetMidX(unionRect), CGRectGetMidY(unionRect));
    CGSize cloudNodeNewSize;
    CGPoint cloudNodeNewPos;
    CGFloat cloudNodeScaleFactor;
    if (unionRectAR > aspectRatio) {
        // Dominant width
        cloudNodeNewSize = CGSizeMake(unionRect.size.width, unionRect.size.width / aspectRatio);
        cloudNodeNewPos = CGPointMake(-unionCenter.x, -unionCenter.y);
        cloudNodeScaleFactor = self.wordCloud.cloudSize.width / unionRect.size.width;
    }
    else {
        // Dominant Height
        cloudNodeNewSize = CGSizeMake(unionRect.size.height * aspectRatio, unionRect.size.height);
        cloudNodeNewPos = CGPointMake(-unionCenter.x, -unionCenter.y);
        cloudNodeScaleFactor = self.wordCloud.cloudSize.height / unionRect.size.height;
    }
    //cloudNodeNewSize = CGSizeMake(cloudNodeNewSize.width*1.1, cloudNodeNewSize.height*1.1);
    self.cloudNode.size = cloudNodeNewSize;
    self.cloudNode.position = CGPointZero;
    [self.cloudNode setScale:cloudNodeScaleFactor];
    
    NSLog(@"UnionRect: %@; UnionCenter: %@; CloudNode: Size: %@ Pos: %@ Scale: %.2f ",NSStringFromCGRect(unionRect),NSStringFromCGPoint(unionCenter),NSStringFromCGSize(cloudNodeNewSize),NSStringFromCGPoint(cloudNodeNewPos),cloudNodeScaleFactor);
    
    /*
    CGPoint center = CGPointMake(-CGRectGetMidX(unionRect),-CGRectGetMidY(unionRect));
    CGSize newSize = CGSizeMake(unionRect.size.width, unionRect.size.height);
    if (aspectRatio * unionRect.size.height > newSize.width ) {
        // Need to increase width to match AR
        newSize.width = aspectRatio * unionRect.size.height;
    }
    else {
        newSize.height = unionRect.size.width / aspectRatio;
    }
    [self.cloudNode setSize:newSize];
    [self.cloudNode setPosition:center];
    
    // Scale to fit wordCloud size
    CGFloat scaleFactor = self.wordCloud.cloudSize.width / self.cloudNode.size.width;
    [self.cloudNode setScale:scaleFactor];
    
    NSLog(@"UnionRect: %@; CloudNode: Size: %@ Pos: %@ Scale: %.2f Frame: %@",NSStringFromCGRect(unionRect),NSStringFromCGSize(newSize),NSStringFromCGPoint(center),scaleFactor,NSStringFromCGRect(self.cloudNode.frame));
     */
}

@end
