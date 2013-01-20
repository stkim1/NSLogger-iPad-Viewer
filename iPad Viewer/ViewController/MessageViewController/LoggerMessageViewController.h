//
//  LoggerMessageViewController.h
//  ipadnslogger
//
//  Created by Almighty Kim on 1/17/13.
//  Copyright (c) 2013 Colorful Glue. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoggerDataManager.h"
#import <CoreData/NSFetchedResultsController.h>


@interface LoggerMessageViewController : UIViewController
<UITableViewDataSource
,UITableViewDelegate
,NSFetchedResultsControllerDelegate>
@property (nonatomic, assign) LoggerDataManager			*dataManager;
@property (nonatomic, assign) IBOutlet UITableView		*tableView;
@end
