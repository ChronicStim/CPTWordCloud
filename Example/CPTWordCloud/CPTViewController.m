//
//  CPTViewController.m
//  CPTWordCloud
//
//  Created by ChronicStim on 11/02/2021.
//  Copyright (c) 2021 ChronicStim. All rights reserved.
//

#import "CPTViewController.h"
#import <CPTWordCloud/CPTWordCloud.h>
#import <CPTWordCloud/CPTWordCloudView.h>
#import "CPTPopoverViewController.h"

@interface CPTViewController ()

@property (nonatomic, strong) UIImage *capturedImage;
@property (weak, nonatomic) IBOutlet CPTWordCloudView *wordCloudView;
@property (weak, nonatomic) IBOutlet UISlider *verticalProbabilitySlider;
@property (weak, nonatomic) IBOutlet UIButton *useRandomFontButton;

- (IBAction)initializeAlphaButtonPressed:(id)sender;
- (IBAction)initializeBetaButtonPressed:(id)sender;
- (IBAction)regenerateCloudButtonPressed:(id)sender;
- (IBAction)clearCloudButtonPressed:(id)sender;
- (IBAction)showImageButtonPressed:(id)sender;
- (IBAction)randomizeFontsButtonPressed:(id)sender;
- (IBAction)showRectButtonPressed:(id)sender;
- (IBAction)verticalWordSliderValueChanged:(id)sender;

@end

@implementation CPTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self initializeWordCloud:@"Alpha"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initializeAlphaButtonPressed:(id)sender {
    if (self.wordCloudView) {
        [self initializeWordCloud:@"Alpha"];
    }
}

- (IBAction)initializeBetaButtonPressed:(id)sender {
    if (self.wordCloudView) {
        [self initializeWordCloud:@"Beta"];
    }
}

- (IBAction)verticalWordSliderValueChanged:(id)sender {
    CGFloat verticalProbability = [(UISlider *)sender value];
    CPTWordCloud *wordCloud = self.wordCloudView.wordCloud;
    wordCloud.probabilityOfWordVertical = verticalProbability;
}

- (IBAction)showRectButtonPressed:(id)sender {
    if (self.wordCloudView.wordBackgroundColor == [UIColor clearColor]) {
        // Turn background display ON
        self.wordCloudView.wordBackgroundColor = [UIColor lightGrayColor];
        [(UIButton *)sender setTitle:@"Hide RECTs" forState:UIControlStateNormal];
    }
    else {
        // Turn background display OFF
        self.wordCloudView.wordBackgroundColor = [UIColor clearColor];
        [(UIButton *)sender setTitle:@"Show RECTs" forState:UIControlStateNormal];
    }
}

- (IBAction)randomizeFontsButtonPressed:(id)sender {
    CPTWordCloud *wordCloud = self.wordCloudView.wordCloud;
    BOOL currentFontSetting = wordCloud.isUsingRandomFontPerWord;
    BOOL newFontSetting = !currentFontSetting;
    wordCloud.usingRandomFontPerWord = newFontSetting;
    wordCloud.selectableFontNames = [wordCloud allSystemFontNames];
    [wordCloud generateCloud];
    // Change button display
    [(UIButton *)sender setTitle:(wordCloud.isUsingRandomFontPerWord ? @"Use Single Font" : @"Use Random Fonts") forState:UIControlStateNormal];
}

- (IBAction)showImageButtonPressed:(id)sender {
    [self.wordCloudView createPDFSaveToDocumentsWithFileName:@"SamplePDFWordCloud.pdf"];
}

- (IBAction)clearCloudButtonPressed:(id)sender {
    
    if (self.wordCloudView) {
        [self.wordCloudView.wordCloud resetCloud];
    }
}

- (IBAction)regenerateCloudButtonPressed:(id)sender {
    if (self.wordCloudView) {
        [self.wordCloudView.wordCloud generateCloud];
    }
}

-(void)initializeWordCloud:(NSString *)mode;
{
    if (nil != self.wordCloudView) {
        
        self.wordCloudView.backgroundColor = [UIColor whiteColor];
        
        CPTWordCloud *wordCloud = self.wordCloudView.wordCloud;
        wordCloud.cloudSize = self.wordCloudView.bounds.size;
        [wordCloud resetCloud];
        
        if ([mode isEqualToString:@"Alpha"]) {

            wordCloud.lowCountColor = [UIColor blueColor];
            wordCloud.highCountColor = [UIColor redColor];

            wordCloud.probabilityOfWordVertical = 0.2f;
            self.verticalProbabilitySlider.value = wordCloud.probabilityOfWordVertical;

            wordCloud.usingRandomFontPerWord = NO;
            [self.useRandomFontButton setTitle:(wordCloud.isUsingRandomFontPerWord ? @"Use Single Font" : @"Use Random Fonts") forState:UIControlStateNormal];

            wordCloud.convertingAllWordsToLowercase = YES;

            [wordCloud addWords:@"Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, `and what is the use of a book,' thought Alice `without pictures or conversation?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her. There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, `Oh dear! Oh dear! I shall be late!' (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural); but when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran across the field after it, and fortunately was just in time to see it pop down a large rabbit-hole under the hedge." delimiter:@" "];
        }
        else if ([mode isEqualToString:@"Beta"]) {
            
            wordCloud.lowCountColor = [UIColor greenColor];
            wordCloud.highCountColor = [UIColor orangeColor];

            wordCloud.probabilityOfWordVertical = 0.2f;
            self.verticalProbabilitySlider.value = wordCloud.probabilityOfWordVertical;

            wordCloud.usingRandomFontPerWord = NO;
            [self.useRandomFontButton setTitle:(wordCloud.isUsingRandomFontPerWord ? @"Use Single Font" : @"Use Random Fonts") forState:UIControlStateNormal];

            wordCloud.convertingAllWordsToLowercase = NO;
            
            [wordCloud addWordsWithCounts:@{@"onto" : @(1),@"picture" : @(2),@"survive" : @(6), @"Gift" : @(5), @"size" : @(1), @"furthermore" : @(2), @"last" : @(4), @"male" : @(1), @"distant" : @(8), @"seed" : @(1), @"anyway" : @(1), @"weapon" : @(3), @"income" : @(5), @"especially" : @(2), @"steal" : @(3), @"whisper" : @(6), @"Offense" : @(3), @"its" : @(4), @"talent" : @(4), @"fresh" : @(8), @"remaining" : @(2), @"makeup" : @(1), @"effective" : @(2), @"thin" : @(1), @"tremendous" : @(5), @"Wisdom" : @(6), @"Worth" : @(7), @"roughly" : @(4), @"empty" : @(11), @"interpret" : @(2), @"engineer" : @(1), @"mad" : @(1), @"celebrity" : @(2), @"Gentleman" : @(10), @"lawn" : @(4), @"debt" : @(3), @"indeed" : @(4), @"feeling" : @(3), @"aside" : @(2), @"crisis" : @(5), @"across" : @(3), @"fall" : @(1), @"difference" : @(1), @"Nation" : @(5), @"floor" : @(11), @"useful" : @(3), @"Capital" : @(13), @"surprised" : @(4), @"include" : @(2)}];
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:kPopoverSegueCPTViewControllerToCPTPopoverViewController]) {
        
        CPTPopoverViewController *destinationController = (CPTPopoverViewController *)[segue destinationViewController];
        self.capturedImage = [self.wordCloudView imageByRenderingView];
        destinationController.wordCloudImage = self.capturedImage;
    }
}

@end
