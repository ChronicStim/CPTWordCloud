//
//  CPTWordCloudView.h
//  CPTWordCloud
//
//  Created by Bob Kutschke on 1/5/22.
//

#import <UIKit/UIKit.h>

@class CPTWordCloudSKView;
@interface CPTWordCloudView : UIView

@property (nonatomic, assign) CGFloat borderWidthAsPercentOfViewWidth; // Allows border to scale while appearing same relative thickness
@property (nonatomic, strong) UIColor *borderColor;
@property (nonatomic, assign) CGFloat cornerRadiusAsPercentOfViewWidth;
@property (nonatomic, strong) UIColor *cloudAreaBackgroundColor;
@property (nonatomic, strong) UIColor *titleColor;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic, strong) NSString *titleString;
@property (nonatomic, assign) CGSize wordCloudInsetsFromBorderAsPercentOfViewWidth;
@property (weak, nonatomic) IBOutlet CPTWordCloudSKView *wordCloudSKView;

-(instancetype)initWithFrame:(CGRect)frame;
-(instancetype)initWithCoder:(NSCoder *)coder;

-(UIImage *)imageByDrawingView;
-(void)drawWordCloudInContext:(CGContextRef)context;
-(NSData *)createPDFSaveToDocuments:(BOOL)saveToDocuments withFileName:(NSString*)aFilename;

@end
