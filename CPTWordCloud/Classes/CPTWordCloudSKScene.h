//
//  CPTWordCloudSKScene.h
//  CPTWordCloud
//
//  Created by Bob Kutschke on 12/17/21.
//

#import <SpriteKit/SpriteKit.h>

@class CPTWordCloud;
@interface CPTWordCloudSKScene : SKScene

@property (nonatomic, weak) CPTWordCloud* wordCloud;
@property (nonatomic) UIColor *wordOutlineColor;
@property (nonatomic, readonly) CGFloat scalingFactor;
@property (nonatomic, readonly) CGPoint cloudOriginShift;

-(instancetype)initWordCloudSKSceneForWordCloud:(CPTWordCloud *)wordCloud withSize:(CGSize)size;
-(void)generateSceneWithSortedWords:(NSArray *)sortedWords;

@end
