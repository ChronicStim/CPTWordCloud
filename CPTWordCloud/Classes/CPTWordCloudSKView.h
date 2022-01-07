//
//  CPTWordCloudSKView.h
//  CPTWordCloud
//
//  Created by Bob Kutschke on 12/17/21.
//

#import <SpriteKit/SpriteKit.h>
#import "CPTWordCloud.h"

@interface CPTWordCloudSKView : SKView  <CPTWordCloudDelegate>

@property (nonatomic, strong, readonly) CPTWordCloud* wordCloud;

-(void)assignWordCloud:(CPTWordCloud *)wordCloud;
-(UIImage *)imageByDrawingView;
-(void)drawWordCloudInContext:(CGContextRef)context;

@end
