//
//  CustomTextField.m
//  StringCheck
//
//  Created by nako on 2015. 4. 10..
//  Copyright (c) 2015년 nako. All rights reserved.
//

#import "CustomTextField.h"

@implementation CustomTextField

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
    if (([theEvent type] == NSKeyDown) && ([theEvent modifierFlags] & NSCommandKeyMask))
    {
        NSResponder * responder = [[self window] firstResponder];
        
        if ((responder != nil) && [responder isKindOfClass:[NSTextView class]])
        {
            NSTextView * textView = (NSTextView *)responder;
            NSRange range = [textView selectedRange];
            bool bHasSelectedTexts = (range.length > 0);
            
            unsigned short keyCode = [theEvent keyCode];
            
            bool bHandled = false;
            
            //6 Z, 7 X, 8 C, 9 V
            if (keyCode == 6)
            {
                if ([[textView undoManager] canUndo])
                {
                    [[textView undoManager] undo];
                    bHandled = true;
                }
            }
            else if (keyCode == 7 && bHasSelectedTexts)
            {
                [textView cut:self];
                bHandled = true;
            }
            else if (keyCode== 8 && bHasSelectedTexts)
            {
                [textView copy:self];
                bHandled = true;
            }
            else if (keyCode == 9)
            {
                [textView paste:self];
                bHandled = true;
            }
            else if( keyCode == 0 && [[self stringValue] length] != 0)
            {
                [[self currentEditor] setSelectedRange:NSMakeRange(0,[[self stringValue] length])];
            }
            
            if (bHandled)
                return YES;
        }
    }
    
    return NO;
}
@end
