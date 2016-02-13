//
//  CustomTable.h
//  StringCheck
//
//  Created by tilltue on 2015. 4. 2..
//  Copyright (c) 2015년 nako. All rights reserved.
//
//  테이블 선택과 마우스 우클릭 context 메뉴를 사용하기 위한 이벤트처리용 custom table class

#import <Cocoa/Cocoa.h>

@protocol ExtendedTableViewDelegate <NSObject>

- (void)tableView:(NSTableView *)tableView didClickedRow:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView didRightClick:(NSInteger)row withEvent:(NSEvent *)theEvent;

@end

@interface CustomTable : NSTableView
@property (nonatomic, weak) id<ExtendedTableViewDelegate> extendedDelegate;
@end
