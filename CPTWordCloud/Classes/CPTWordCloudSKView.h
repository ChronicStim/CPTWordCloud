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
- (UIImage *)imageByRenderingView;
-(UIImage *)imageByDrawingView;
-(NSData *)createPDFSaveToDocuments:(BOOL)saveToDocuments withFileName:(NSString*)aFilename;
-(void)drawInPDFContext:(CGContextRef)pdfContext;

@end
