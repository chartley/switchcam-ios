//
//  MenuPendingUploadDSD.h
//  SwitchcamPro
//
//  Created by William Ketterer on 12/16/12.
//  Copyright (c) 2012 William Ketterer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PendingUploadCell.h"
@class MenuViewController;

@interface MenuPendingUploadDSD : NSObject <UITableViewDataSource, UITableViewDelegate, PendingUploadCellDelegate>

@property (weak, nonatomic) MenuViewController *menuViewController;

@end
