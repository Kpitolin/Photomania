//
//  URLViewController.m
//  Photomania
//
//  Created by Kevin on 10/06/2014.
//  Copyright (c) 2014 ___kevinPitolin___. All rights reserved.
//

#import "URLViewController.h"
@interface URLViewController ()


@property (weak, nonatomic) IBOutlet UITextView *URLTextView;


@end

@implementation URLViewController


-(void) setUrl:(NSURL *)url
{
    _url = url ;
    [self updateUI];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self updateUI];
}
- (void) updateUI
{
    self.URLTextView.text= [self.url absoluteString];
}

@end
