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

- (void)loadView
{
    [super loadView];
 
//    self.wordCloud.cloudSize = self.view.bounds.size;
//    self.wordCloud.lowCountColor = [UIColor yellowColor];
//    self.wordCloud.highCountColor = [UIColor greenColor];
//    
//    [self.wordCloud addWords:@"Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, `and what is the use of a book,' thought Alice `without pictures or conversation?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her. There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, `Oh dear! Oh dear! I shall be late!' (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural); but when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran across the field after it, and fortunately was just in time to see it pop down a large rabbit-hole under the hedge." delimiter:@" "];

}

-(CPTWordCloud *)wordCloud;
{
    if (nil != _wordCloud) {
        return _wordCloud;
    }
    _wordCloud = [[CPTWordCloud alloc] init];
    
    _wordCloud.cloudSize = self.view.bounds.size;
    _wordCloud.lowCountColor = [UIColor yellowColor];
    _wordCloud.highCountColor = [UIColor greenColor];
    
    _wordCloud.delegate = self.wordCloudView;
    
    return _wordCloud;
}

-(CPTWordCloudView *)wordCloudView;
{
    if (nil != _wordCloudView) {
        return _wordCloudView;
    }
    _wordCloudView = [[CPTWordCloudView alloc] initForWordCloud:self.wordCloud withFrame:self.view.bounds];
    _wordCloudView.delegate = self;
    [self.view addSubview:_wordCloudView];
    
    return _wordCloudView;
}

-(void)clearWordCloudView;
{
    [self.wordCloud resetCloud];
}

-(void)regenerateWordCloudView;
{
    [self.wordCloud generateCloud];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
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
