//
//  CPTWordCloudView.h
//  CPTWordCloud
//
//  Created by Bob Kutschke on 1/5/22.
//

#import <UIKit/UIKit.h>

@class CPTWordCloudSKView, CPTWordCloud;
@interface CPTWordCloudView : UIView

@property (nonatomic, assign) IBInspectable CGFloat borderWidthAsPercentOfViewWidth; // Allows border to scale while appearing same relative thickness
@property (nonatomic, strong) IBInspectable UIColor *borderColor;
@property (nonatomic, assign) IBInspectable CGFloat cornerRadiusAsPercentOfViewWidth;
@property (nonatomic, strong) IBInspectable UIColor *cloudAreaBackgroundColor;
@property (nonatomic, strong) IBInspectable UIColor *titleColor;
@property (nonatomic, strong) IBInspectable UIFont *titleFont;
@property (nonatomic, strong) IBInspectable NSString *titleString;
@property (nonatomic, assign) IBInspectable CGSize wordCloudInsetsFromBorderAsPercentOfViewWidth;
@property (weak, nonatomic) IBOutlet CPTWordCloudSKView *wordCloudSKView;
@property (nonatomic, weak, readonly) CPTWordCloud* wordCloud;

-(instancetype)initWithFrame:(CGRect)frame;
-(instancetype)initWithCoder:(NSCoder *)coder;
-(void)assignWordCloud:(CPTWordCloud *)wordCloud;

-(CGSize)autoLayoutCalculatedWordCloudSKViewSize; // is applied to the CPTWordCloud automatically when WordCloud is assigned.

-(UIImage *)imageByDrawingView;
-(void)drawWordCloudInContext:(CGContextRef)context;
-(NSData *)createPDFSaveToDocuments:(BOOL)saveToDocuments withFileName:(NSString*)aFilename;

@end
