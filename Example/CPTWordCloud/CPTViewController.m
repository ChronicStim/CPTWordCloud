//
//  CPTViewController.m
//  CPTWordCloud
//
//  Created by ChronicStim on 11/02/2021.
//  Copyright (c) 2021 ChronicStim. All rights reserved.
//

#import "CPTViewController.h"
#import <CPTWordCloud/CPTWordCloudView.h>
#import <CPTWordCloud/CPTWordCloudSKView.h>
#import "CPTPopoverViewController.h"

@interface CPTViewController ()

@property (nonatomic, strong) UIImage *capturedImage;
@property (nonatomic) CPTWordCloudView *wordCloudView;
@property (weak, nonatomic) IBOutlet UISlider *verticalProbabilitySlider;
@property (weak, nonatomic) IBOutlet UIButton *useRandomFontButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *fontSizingMethodSelector;
@property (weak, nonatomic) IBOutlet UISegmentedControl *rotationMethodSegmentedControl;
@property (nonatomic) CPTWordCloud *wordCloudAlpha;
@property (nonatomic) CPTWordCloud *wordCloudBeta;
@property (weak, nonatomic) IBOutlet UIView *wordCloudContainmentView;

- (IBAction)initializeAlphaButtonPressed:(id)sender;
- (IBAction)initializeBetaButtonPressed:(id)sender;
- (IBAction)regenerateCloudButtonPressed:(id)sender;
- (IBAction)showImageButtonPressed:(id)sender;
- (IBAction)randomizeFontsButtonPressed:(id)sender;
- (IBAction)showRectButtonPressed:(id)sender;
- (IBAction)verticalWordSliderValueChanged:(id)sender;
- (IBAction)filterStopwordsSwitchChanged:(id)sender;
- (IBAction)fontSizingSegmentedSwitchSelected:(id)sender;
- (IBAction)blendColorModeSwitchValueChanged:(id)sender;
- (IBAction)rotationMethodSegmentedControlValueChanged:(id)sender;

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

- (IBAction)rotationMethodSegmentedControlValueChanged:(id)sender {
    int selection = (int)[(UISegmentedControl *)sender selectedSegmentIndex];
    self.wordCloudView.wordCloudSKView.wordCloud.rotationMode = (CPTWordRotationMode)selection;
}

- (IBAction)blendColorModeSwitchValueChanged:(id)sender {
    BOOL blendColorUsingHSB = [(UISwitch *)sender isOn];
    self.wordCloudView.wordCloudSKView.wordCloud.colorMappingHSBBased = blendColorUsingHSB;
}

- (IBAction)fontSizingSegmentedSwitchSelected:(id)sender {
    NSInteger segmentSelected = [(UISegmentedControl *)sender selectedSegmentIndex];
    CPTWordScalingMode fontSizingMode = CPTWordScalingMode_rank;
    switch (segmentSelected) {
        case 0:
            fontSizingMode = CPTWordScalingMode_rank;
            break;
        case 1:
            fontSizingMode = CPTWordScalingMode_linearN;
            break;
        case 2:
            fontSizingMode = CPTWordScalingMode_expN;
            break;
        case 3:
            fontSizingMode = CPTWordScalingMode_logN;
            break;
        default:
            break;
    }
    
    self.wordCloudView.wordCloudSKView.wordCloud.scalingMode = fontSizingMode;
}

- (IBAction)filterStopwordsSwitchChanged:(id)sender {
    BOOL isSwitchOn = [(UISwitch *)sender isOn];
    self.wordCloudView.wordCloudSKView.wordCloud.filteringStopWords = isSwitchOn;
}

- (IBAction)verticalWordSliderValueChanged:(id)sender {
    CGFloat verticalProbability = [(UISlider *)sender value];
    CPTWordCloud *wordCloud = self.wordCloudView.wordCloudSKView.wordCloud;
    wordCloud.probabilityOfWordRotation = verticalProbability;
}

- (IBAction)showRectButtonPressed:(id)sender {
    if ([self.wordCloudView.wordCloudSKView.wordCloud wordOutlineColor] == [UIColor clearColor]) {
        // Turn background display ON
        self.wordCloudView.wordCloudSKView.wordCloud.wordOutlineColor = [UIColor lightGrayColor];
        [(UIButton *)sender setTitle:@"Hide RECTs" forState:UIControlStateNormal];
    }
    else {
        // Turn background display OFF
        self.wordCloudView.wordCloudSKView.wordCloud.wordOutlineColor = [UIColor clearColor];
        [(UIButton *)sender setTitle:@"Show RECTs" forState:UIControlStateNormal];
    }
}

- (IBAction)randomizeFontsButtonPressed:(id)sender {
    CPTWordCloud *wordCloud = self.wordCloudView.wordCloudSKView.wordCloud;
    BOOL currentFontSetting = wordCloud.isUsingRandomFontPerWord;
    BOOL newFontSetting = !currentFontSetting;
    wordCloud.usingRandomFontPerWord = newFontSetting;
    wordCloud.selectableFontNames = [wordCloud allSystemFontNames];
    [wordCloud updateCloudSceneWithRegenerateNodes:@(YES)];
    // Change button display
    [(UIButton *)sender setTitle:(wordCloud.isUsingRandomFontPerWord ? @"Use Single Font" : @"Use Random Fonts") forState:UIControlStateNormal];
}

- (IBAction)showImageButtonPressed:(id)sender {
    [self.wordCloudView createPDFSaveToDocuments:YES withFileName:@"SamplePDFWordCloud.pdf"];
}

- (IBAction)regenerateCloudButtonPressed:(id)sender {
    if (self.wordCloudView) {
        [self.wordCloudView.wordCloudSKView.wordCloud updateCloudSceneWithRegenerateNodes:@(YES)];
    }
}

-(CPTWordCloud *)wordCloudAlpha;
{
    if (nil != _wordCloudAlpha) {
        return _wordCloudAlpha;
    }
    
    _wordCloudAlpha = [[CPTWordCloud alloc] init];
    _wordCloudAlpha.lowCountColor = [UIColor colorWithRed:0.022 green:0.000 blue:0.751 alpha:1.000];
    _wordCloudAlpha.highCountColor = [UIColor colorWithRed:0.751 green:0.000 blue:0.052 alpha:1.000];
    
    _wordCloudAlpha.scalingMode = CPTWordScalingMode_rank;
    
    _wordCloudAlpha.probabilityOfWordRotation = 0.8f;
    _wordCloudAlpha.rotationMode = CPTWordRotationMode_Deg30;
    
    _wordCloudAlpha.usingRandomFontPerWord = NO;
    
    _wordCloudAlpha.convertingAllWordsToLowercase = YES;
    
    [_wordCloudAlpha addWords:@"Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, `and what is the use of a book,' thought Alice `without pictures or conversation?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her. There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, `Oh dear! Oh dear! I shall be late!' (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural); but when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran across the field after it, and fortunately was just in time to see it pop down a large rabbit-hole under the hedge." delimiter:@" "];

    return _wordCloudAlpha;
}

-(CPTWordCloud *)wordCloudBeta;
{
    if (nil != _wordCloudBeta) {
        return _wordCloudBeta;
    }
    
    _wordCloudBeta = [[CPTWordCloud alloc] init];
    
    _wordCloudBeta.minFontSize = 50;
    _wordCloudBeta.maxFontSize = 200;
    
    _wordCloudBeta.lowCountColor = [UIColor greenColor];
    _wordCloudBeta.highCountColor = [UIColor orangeColor];
    
    _wordCloudBeta.wordWithCountOfZeroDisplayed = YES;
    
    _wordCloudBeta.scalingMode = CPTWordScalingMode_rank;
    
    _wordCloudBeta.rotationMode = CPTWordRotationMode_HorizVertOnly;
    _wordCloudBeta.probabilityOfWordRotation = 0.2f;
    
    _wordCloudBeta.usingRandomFontPerWord = NO;
    
    _wordCloudBeta.convertingAllWordsToLowercase = NO;
    
    [_wordCloudBeta addWordsWithCounts:@{@"onto" : @(1),@"picture" : @(0),@"survive" : @(6), @"Gift" : @(5), @"size" : @(1), @"furthermore" : @(2), @"last" : @(4), @"male" : @(1), @"distant" : @(8), @"seed" : @(1), @"anyway" : @(0), @"weapon" : @(3), @"income" : @(5), @"especially" : @(2), @"steal" : @(3), @"whisper" : @(6), @"Offense" : @(3), @"its" : @(4), @"talent" : @(4), @"fresh" : @(8), @"remaining" : @(2), @"makeup" : @(1), @"effective" : @(2), @"thin" : @(0), @"tremendous" : @(5), @"Wisdom" : @(6), @"Worth" : @(7), @"roughly" : @(4), @"empty" : @(11), @"interpret" : @(2), @"engineer" : @(1), @"mad" : @(0), @"celebrity" : @(2), @"Gentleman" : @(10), @"lawn" : @(4), @"debt" : @(3), @"indeed" : @(4), @"feeling" : @(3), @"aside" : @(2), @"crisis" : @(5), @"across" : @(3), @"fall" : @(1), @"difference" : @(1), @"Nation" : @(5), @"floor" : @(0), @"useful" : @(3), @"Capital" : @(13), @"surprised" : @(4), @"include" : @(0)}];

    return _wordCloudBeta;
}

-(CPTWordCloudView *)wordCloudView;
{
    if (nil != _wordCloudView) {
        return _wordCloudView;
    }
    
    _wordCloudView = (CPTWordCloudView *)[[[NSBundle bundleForClass:[CPTWordCloud class]] loadNibNamed:@"CPTWordCloudView" owner:self options:nil] objectAtIndex:0];
    _wordCloudView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.wordCloudContainmentView addSubview:_wordCloudView];
    [_wordCloudView.widthAnchor constraintEqualToAnchor:self.wordCloudContainmentView.widthAnchor].active = YES;
    [_wordCloudView.heightAnchor constraintEqualToAnchor:self.wordCloudContainmentView.heightAnchor].active = YES;
    [_wordCloudView.centerXAnchor constraintEqualToAnchor:self.wordCloudContainmentView.centerXAnchor].active = YES;
    [_wordCloudView.centerYAnchor constraintEqualToAnchor:self.wordCloudContainmentView.centerYAnchor].active = YES;
    
    return _wordCloudView;
}

-(void)initializeWordCloud:(NSString *)mode;
{
    if (nil != self.wordCloudView) {
        
        [self.wordCloudView removeFromSuperview];
        self.wordCloudView = nil;
        
        if ([mode isEqualToString:@"Alpha"]) {

            [self.wordCloudView.wordCloudSKView assignWordCloud:self.wordCloudAlpha];
            self.wordCloudView.titleString = @"Word Cloud Demo Alpha";
            
            [self.fontSizingMethodSelector setSelectedSegmentIndex:(int)_wordCloudAlpha.scalingMode];
            self.verticalProbabilitySlider.value = _wordCloudAlpha.probabilityOfWordRotation;
            self.rotationMethodSegmentedControl.selectedSegmentIndex = (int)_wordCloudAlpha.rotationMode;
            [self.useRandomFontButton setTitle:(_wordCloudAlpha.isUsingRandomFontPerWord ? @"Use Single Font" : @"Use Random Fonts") forState:UIControlStateNormal];

        }
        else if ([mode isEqualToString:@"Beta"]) {
            
            [self.wordCloudView.wordCloudSKView assignWordCloud:self.wordCloudBeta];
            self.wordCloudView.titleString = @"Word Cloud Demo Beta";

            [self.fontSizingMethodSelector setSelectedSegmentIndex:(int)_wordCloudBeta.scalingMode];
            self.verticalProbabilitySlider.value = _wordCloudBeta.probabilityOfWordRotation;
            self.rotationMethodSegmentedControl.selectedSegmentIndex = (int)_wordCloudBeta.rotationMode;
            [self.useRandomFontButton setTitle:(_wordCloudBeta.isUsingRandomFontPerWord ? @"Use Single Font" : @"Use Random Fonts") forState:UIControlStateNormal];

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
        self.capturedImage = [self.wordCloudView imageByDrawingView];
        destinationController.wordCloudImage = self.capturedImage;
    }
}

@end
