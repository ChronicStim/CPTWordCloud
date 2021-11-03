//
//  CPTWordCloudViewController.h
//  elements
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import "CPTWordCloudView.h"
#import "CPTWordCloud.h"

@protocol CPTWordCloudViewControllerDelegate;

@interface CPTWordCloudViewController : UIViewController <CPTWordCloudViewDelegate>

@property (nonatomic, retain) id<CPTWordCloudViewControllerDelegate> delegate;
@property (nonatomic, readonly) CPTWordCloud *wordCloud;
@property (nonatomic, readonly) CPTWordCloudView *wordCloudView;

-(void)clearWordCloudView;
-(void)regenerateWordCloudView;

@end


@protocol CPTWordCloudViewControllerDelegate <NSObject>

@optional

- (void)wordCloud:(CPTWordCloud *)wc didTapWord:(NSString *)word atPoint:(CGPoint)point;

@end
