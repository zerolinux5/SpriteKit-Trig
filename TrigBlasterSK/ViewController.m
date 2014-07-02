//
//  ViewController.m
//  TrigBlasterSK
//
//  Created by Jesus Magana on 7/2/14.
//  Copyright (c) 2014 ZeroLinux5. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    // Configure the view.
    // Configure the view after it has been sized for the correct orientation.
    [self startScene];
}

- (void)startScene
{
    SKView *skView = (SKView *)self.view;
    if (!skView.scene) {
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
        
        // Create and configure the scene.
        MyScene *theScene = [MyScene sceneWithSize:skView.bounds.size];
        theScene.scaleMode = SKSceneScaleModeAspectFill;
        
        // Present the scene.
        [skView presentScene:theScene];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
