//
//  CustomTable.m
//  StringCheck
//
//  Created by tilltue on 2015. 4. 2..
//  Copyright (c) 2015년 nako. All rights reserved.
//

#import "CustomTable.h"

@implementation CustomTable

- (void)mouseDown:(NSEvent *)theEvent
{
    NSLog(@"%@",theEvent);
    NSPoint globalLocation = [theEvent locationInWindow];
    NSPoint localLocation = [self convertPoint:globalLocation fromView:nil];
    NSInteger clickedRow = [self rowAtPoint:localLocation];
    
    [super mouseDown:theEvent];
    
    if (clickedRow != -1 && theEvent.clickCount == 1) {
        [self.extendedDelegate tableView:self didClickedRow:clickedRow];
    }else if (clickedRow != -1 && theEvent.clickCount == 2) {
        [self.extendedDelegate tableView:self didDoubleClickedRow:clickedRow withEvent:theEvent];
    }
}

@end
