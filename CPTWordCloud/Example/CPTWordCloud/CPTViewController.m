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

- (IBAction)initializeCloudButtonPressed:(id)sender;
- (IBAction)regenerateCloudButtonPressed:(id)sender;
- (IBAction)clearCloudButtonPressed:(id)sender;
- (IBAction)showImageButtonPressed:(id)sender;
- (IBAction)randomizeFontsButtonPressed:(id)sender;

@end

@implementation CPTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self initializeWordCloud];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initializeCloudButtonPressed:(id)sender {
    if (self.wordCloudView) {
        [self initializeWordCloud];
    }
}

- (IBAction)randomizeFontsButtonPressed:(id)sender {
    CPTWordCloud *wordCloud = self.wordCloudView.wordCloud;
    BOOL currentFontSetting = wordCloud.isUsingRandomFontPerWord;
    BOOL newFontSetting = !currentFontSetting;
    wordCloud.usingRandomFontPerWord = newFontSetting;
    wordCloud.selectableFontNames = [wordCloud allSystemFontNames];
    [wordCloud generateCloud];
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

-(void)initializeWordCloud;
{
    if (nil != self.wordCloudView) {
        
        self.wordCloudView.backgroundColor = [UIColor whiteColor];
        
        CPTWordCloud *wordCloud = self.wordCloudView.wordCloud;
        wordCloud.cloudSize = self.wordCloudView.bounds.size;
        wordCloud.lowCountColor = [UIColor blueColor];
        wordCloud.highCountColor = [UIColor redColor];
        wordCloud.probabilityOfWordVertical = 0.2f;
        wordCloud.usingRandomFontPerWord = NO;
//        wordCloud.selectableFontNames = [wordCloud allSystemFontNames];
        
        [wordCloud addWords:@"Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it, `and what is the use of a book,' thought Alice `without pictures or conversation?' So she was considering in her own mind (as well as she could, for the hot day made her feel very sleepy and stupid), whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her. There was nothing so very remarkable in that; nor did Alice think it so very much out of the way to hear the Rabbit say to itself, `Oh dear! Oh dear! I shall be late!' (when she thought it over afterwards, it occurred to her that she ought to have wondered at this, but at the time it all seemed quite natural); but when the Rabbit actually took a watch out of its waistcoat-pocket, and looked at it, and then hurried on, Alice started to her feet, for it flashed across her mind that she had never before seen a rabbit with either a waistcoat-pocket, or a watch to take out of it, and burning with curiosity, she ran across the field after it, and fortunately was just in time to see it pop down a large rabbit-hole under the hedge." delimiter:@" "];
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
