//
//  MDDragDropView.m
//  StringCheck
//
//  Created by nako on 2015. 3. 22..
//  Copyright (c) 2015년 nako. All rights reserved.
//

#import "MDDragDropView.h"

@interface MDDragDropView()
{
    NSMutableDictionary *draggedFiles;
}
@end

@implementation MDDragDropView

- (void)awakeFromNib
{
    draggedFiles = [NSMutableDictionary new];
    //NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSFilenamesPboardType] )
    {
        if (sourceDragMask & NSDragOperationCopy)
        {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
    
    if ( [[pboard types] containsObject:NSURLPboardType] )
    {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        [self.dropdelegate parseData:self withUrl:fileURL];
    }
    return YES;
}

@end