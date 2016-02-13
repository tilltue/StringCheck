//
//  MDDragDropView.h
//  StringCheck
//
//  Created by nako on 2015. 3. 22..
//  Copyright (c) 2015년 nako. All rights reserved.
//
//  Drag & Drop 처리를 위한 open source

#import <Cocoa/Cocoa.h>

@class MDDragDropView;

@protocol DropDelegate <NSObject>
-(void)parseData:(MDDragDropView *)dragView withUrl:(NSURL *)fileURL;
@end

@interface MDDragDropView : NSView
@property (nonatomic) id<DropDelegate>dropdelegate;
@end