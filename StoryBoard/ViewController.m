//
//  ViewController.m
//  StoryBoard
//
//  Created by 徐银 on 15/11/26.
//  Copyright © 2015年 徐银. All rights reserved.
//

#import "ViewController.h"
#import "TackBookListViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)addressBook:(id)sender{
    TackBookListViewController * adreesBook = [[TackBookListViewController alloc]init];
    [self.navigationController pushViewController:adreesBook animated:YES];
}
@end
