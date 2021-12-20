//
//  CPTWordCloudSKScene.h
//  CPTWordCloud
//
//  Created by Bob Kutschke on 12/17/21.
//

#import <SpriteKit/SpriteKit.h>

@class CPTWordCloud;
@interface CPTWordCloudSKScene : SKScene

@property (nonatomic, strong, readonly) CPTWordCloud* wordCloud;
@property (nonatomic) UIColor *wordOutlineColor;

-(instancetype)initWordCloudSKSceneForWordCloud:(CPTWordCloud *)wordCloud withSize:(CGSize)size;
-(void)generateSceneWithSortedWords:(NSArray *)sortedWords;

@end
