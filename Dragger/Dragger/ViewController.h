//
//  ViewController.h
//  Dragger
//
//  Created by Almighty Kim on 3/27/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, assign) IBOutlet UITableView *filterList;
- (IBAction)doSomething:(id)sender;
@end
