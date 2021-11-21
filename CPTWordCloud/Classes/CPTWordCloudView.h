//
//  CPTWordCloudView.h
//  WordCloud
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import "CPTWordCloud.h"

@protocol CPTWordCloudViewDelegate;

@interface CPTWordCloudView : UIView <CPTWordCloudDelegate>

@property (nonatomic, retain) id<CPTWordCloudViewDelegate> delegate;
@property (nonatomic, strong, readonly) CPTWordCloud* wordCloud;

@property (nonatomic) float borderWidth;
@property (nonatomic) UIColor* borderColor;
@property (nonatomic) float cornerRadius;
@property (nonatomic, retain, readonly) NSArray* words;
@property (nonatomic, readonly) double scalingFactor;
@property (nonatomic, readonly) double xShift;
@property (nonatomic, readonly) double yShift;

/// Used to adjust scaling of the final wordCloud to prevent cutting off glyphs that drop below the baseline or extend slightly past final margins. (Default = 10,10,10,10)
@property (nonatomic) UIEdgeInsets cloudInsetMargins;

@property (nonatomic) UIColor *wordBackgroundColor;

- (id) initForWordCloud:(CPTWordCloud *)wordCloud;
- (id) initForWordCloud:(CPTWordCloud *)wordCloud withFrame:(CGRect)frame;
-(void) highlightWord:(NSString *)stringWord;
- (void) highlightWords:(NSArray*)stringWords color:(UIColor*)color;
- (void) clearHighlights;

- (UIImage *)imageByRenderingView;
-(UIImage *)imageByDrawingView;
-(NSData *)createPDFSaveToDocuments:(BOOL)saveToDocuments withFileName:(NSString*)aFilename;
-(void)drawInPDFContext:(CGContextRef)pdfContext;

@end

@protocol CPTWordCloudViewDelegate <NSObject>

@optional

- (void) wordCloudView:(CPTWordCloudView*)wcView didTapWord:(NSString*)word atRect:(CGRect)rect;

@end
