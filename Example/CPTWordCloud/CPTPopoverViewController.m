//
//  CPTPopoverViewController.m
//  CPTWordCloud_Example
//
//  Created by Bob Kutschke on 11/5/21.
//  Copyright © 2021 ChronicStim. All rights reserved.
//

#import "CPTPopoverViewController.h"

@interface CPTPopoverViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation CPTPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated;
{
    [super viewWillAppear:animated];
    
    if (nil != self.wordCloudImage) {
        self.imageView.image = self.wordCloudImage;
    }
}

-(void)setWordCloudImage:(UIImage *)wordCloudImage;
{
    if (wordCloudImage != _wordCloudImage) {
        _wordCloudImage = wordCloudImage;
        
        self.imageView.image = self.wordCloudImage;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
