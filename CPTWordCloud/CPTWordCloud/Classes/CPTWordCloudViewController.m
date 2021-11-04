//
//  CPTWordCloudViewController.m
//  elements
//
//  Created by ChronicStim on 11/02/21.
//  Copyright (c) 2021. All rights reserved.
//

#import "CPTWordCloudViewController.h"
#import "CPTWordCloud.h"
#import "CPTWord.h"
#import "CPTWordCloudView.h"

@interface CPTWordCloudViewController ()
{

}
@property (nonatomic, readwrite) CPTWordCloud *wordCloud;
@property (nonatomic, readwrite) CPTWordCloudView *wordCloudView;

@end

@implementation CPTWordCloudViewController

@synthesize wordCloud = _wordCloud;

- (id)init
{
    return [self initWithNibName:nil bundle:nil];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {

    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder;
{
    self = [super initWithCoder:coder];
    if (self) {
        
    }
    return self;
}

-(void)awakeFromNib;
{
    [super awakeFromNib];
    
    [self initializeWordCloudViewController];
}

-(void)initializeWordCloudViewController;
{
    self.wordCloud = [[CPTWordCloud alloc] init];
    self.wordCloud.cloudSize = self.view.bounds.size;
    
    self.wordCloudView = [[CPTWordCloudView alloc] initForWordCloud:self.wordCloud withFrame:self.view.bounds];

    self.wordCloud.delegate = self.wordCloudView;
    self.wordCloudView.delegate = self;
    [self.view addSubview:self.wordCloudView];
}

-(void)clearWordCloudView;
{
    [self.wordCloud resetCloud];
}

-(void)regenerateWordCloudView;
{
    [self.wordCloud generateCloud];
}

-(void)viewDidLayoutSubviews;
{
    [super viewDidLayoutSubviews];
    
    if (!CGSizeEqualToSize(self.view.bounds.size, self.wordCloud.cloudSize)) {
        self.wordCloud.cloudSize = self.view.bounds.size;
    }
    if (!CGSizeEqualToSize(self.view.bounds.size, self.wordCloudView.bounds.size)) {
        self.wordCloudView.frame = self.view.bounds;
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator;
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self.wordCloudView setNeedsDisplay];
}

// CPTWordCloudViewDelegate
- (void)wordCloudView:(CPTWordCloudView *)wcView didTapWord:(CPTWord *)word atPoint:(CGPoint)point
{
    [self.wordCloudView highlightWord:word.text];
    if ([self.delegate respondsToSelector:@selector(wordCloud:didTapWord:atPoint:)]) {
        [self.delegate wordCloud:self.wordCloud didTapWord:word.text atPoint:point];
    }
}

@end
