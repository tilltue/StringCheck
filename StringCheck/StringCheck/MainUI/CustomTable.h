//
//  CustomTable.h
//  StringCheck
//
//  Created by tilltue on 2015. 4. 2..
//  Copyright (c) 2015년 nako. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ExtendedTableViewDelegate <NSObject>

- (void)tableView:(NSTableView *)tableView didClickedRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView didDoubleClickedRow:(NSInteger)row withEvent:(NSEvent *)theEvent;

@end

@interface CustomTable : NSTableView
@property (nonatomic, weak) id<ExtendedTableViewDelegate> extendedDelegate;
@end
