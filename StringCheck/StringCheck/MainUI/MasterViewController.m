//
//  MasterViewController.m
//  POStringCheck
//
//  Created by nako on 2015. 3. 22..
//  Copyright (c) 2015년 nako. All rights reserved.
//

#import "MasterViewController.h"
#import <Python/Python.h>
#import "MDDragDropView.h"

@interface LStringObject : NSObject
@property (nonatomic, strong) NSString *lang;
@property (nonatomic, strong) NSString *line;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) BOOL insert;
@property (nonatomic, assign) BOOL sameClass;
@end

@implementation LStringObject
@end

@interface MasterViewController () <DropDelegate,NSTableViewDataSource,NSTableViewDelegate,ExtendedTableViewDelegate,NSTextFieldDelegate>
{
    PyObject *_stringCheck;
    IBOutlet MDDragDropView *_dragAndDropViewAppStringPath;
    IBOutlet MDDragDropView *_dragAndDropViewLoStringPath;
    IBOutlet NSImageView *_imageView;
    IBOutlet NSTextField *_textFiledAppStringPath;
    IBOutlet NSTextField *_textFiledLoStringPath;
    
    IBOutlet NSTextField *_classTextField;
    IBOutlet NSTextField *_keywordTextField;
    IBOutlet NSTextField *_valueTextField;
    IBOutlet NSTextField *_gskeywordTextField;
    IBOutlet NSButton *_submitButton;
    IBOutlet NSButton *_nonDuplicateCheck;
    IBOutlet NSButton *_nonSearchDuplicateCheck;
    IBOutlet NSButton *_insertAllButton;
    IBOutlet NSButton *_addPrefixButton;
    
    IBOutlet CustomTable *_resultTable;
    
    NSInteger _clickRow;
    
    NSMutableArray *_resultArr;
}
@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _resultTable.extendedDelegate = self;
    
    _resultArr = [NSMutableArray new];
    
    _dragAndDropViewAppStringPath.dropdelegate = self;
    _dragAndDropViewLoStringPath.dropdelegate = self;
    
    Py_Initialize();
    
    PyObject *sysModule = PyImport_ImportModule("sys");
    PyObject *sysModuleDict = PyModule_GetDict(sysModule);
    PyObject *pathObject = PyDict_GetItemString(sysModuleDict, "path");
    
    NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources"];
    PyObject_CallMethod(pathObject, "insert", "(is)", 0, [bundlePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    Py_DECREF(sysModule); // borrowed reference
    
    PyObject *StringModule = PyImport_ImportModule("StringCheck");
    
    PyObject *StringCheck = PyDict_GetItemString(PyModule_GetDict(StringModule), "StringCheck");
    _stringCheck = PyObject_CallObject(StringCheck, NULL);
    
    Py_DECREF(StringModule);
    Py_DECREF(StringCheck);
    //[self performSelector:@selector(test) withObject:nil afterDelay:.1];
    NSString *path = [self getPath:@"appStringPath"];
    if( path != nil ){
        [self performSelector:@selector(stringLoad:) withObject:path afterDelay:0.1];
        _textFiledAppStringPath.stringValue = path;
    }
    path = [self getPath:@"localStringPath"];
    if( path != nil ){
        [self performSelector:@selector(localStringLoad:) withObject:path afterDelay:0.1];
        _textFiledLoStringPath.stringValue = path;
    }
}

#pragma mark - Python binding

- (void)stringLoad:(NSString *)path
{
    PyObject_CallMethod(_stringCheck,"loadString", "(s)",[path UTF8String]);
}

- (void)localStringLoad:(NSString *)path
{
    PyObject_CallMethod(_stringCheck,"loadLocalString", "(s)",[path UTF8String]);
}

- (void)writeLString:(LStringObject *)object
{
    NSString *value = object.value;
    if( _addPrefixButton.state ){
        value = [NSString stringWithFormat:@"(번)%@",value];
    }
    PyObject_CallMethod(_stringCheck,"writeLocalString", "(sssssd)",[object.line UTF8String],[object.lang UTF8String],[object.name UTF8String],[object.key UTF8String],[value UTF8String],object.sameClass);
}

- (void)insertLString:(LStringObject *)object
{
    PyObject *pyObject = PyObject_CallMethod(_stringCheck,"insertString", "(sss)",[object.name UTF8String],[object.key UTF8String],[object.value UTF8String]);
    if( pyObject != nil ){
        Py_ssize_t len = PyList_Size(pyObject);
        NSMutableArray *list = [NSMutableArray new];
        Py_ssize_t i = 0;
        for (i = 0; i < len; i++) {
            PyObject *objcObject = PyList_GetItem(pyObject, (Py_ssize_t)i);
            if (objcObject != nil) {
                NSString *string = [NSString stringWithCString:PyString_AsString(objcObject) encoding:NSUTF8StringEncoding];
                [list addObject:string];
            }
        }
        [_resultArr removeAllObjects];
        if(  list.count > 0 ){
            [_resultArr addObject:@"유사 클래스의 마지막 라인"];
            _insertAllButton.enabled = YES;
            for( NSString *value in list )
            {
                NSArray *array = [self parseValue:value];
                if( array != nil && array.count == 5){
                    LStringObject *object = [LStringObject new];
                    object.lang = array[0];
                    object.line = array[1];
                    object.name = array[2];
                    object.key  = array[3];
                    object.value= array[4];
                    [_resultArr addObject:object];
                    LStringObject *addObject = [LStringObject new];
                    addObject.sameClass = [[array[2] lowercaseString] isEqualToString:[_keywordTextField.stringValue lowercaseString]];
                    addObject.lang = array[0];
                    addObject.line = [NSString stringWithFormat:@"%d",[array[1] intValue] + 1];
                    addObject.name = addObject.sameClass?object.name:_classTextField.stringValue;
                    addObject.key  = _keywordTextField.stringValue;
                    addObject.value= _valueTextField.stringValue;
                    addObject.insert = YES;
                    [_resultArr addObject:addObject];
                }
            }
            [_resultTable reloadData];
        }else{
            _insertAllButton.enabled = NO;
        }
        
    }
}

#pragma mark - Dragview delegate

- (void)parseData:(MDDragDropView *)dragView withUrl:(NSURL *)fileURL
{
    if( dragView == _dragAndDropViewAppStringPath ){
        [self savePath:[fileURL path] forKey:@"appStringPath"];
        _textFiledAppStringPath.stringValue = [fileURL path];
        [self performSelector:@selector(stringLoad:) withObject:[fileURL path] afterDelay:0.1];
    }else if( dragView == _dragAndDropViewLoStringPath ){
        [self savePath:[fileURL path] forKey:@"localStringPath"];
        _textFiledLoStringPath.stringValue = [fileURL path];
        [self performSelector:@selector(localStringLoad:) withObject:[fileURL path] afterDelay:0.1];
//        PyObject_CallMethod(_stringCheck,"loadString", "(s)",[[fileURL path] UTF8String]);
    }
}

#pragma mark  - Save userdefault setting

- (void)savePath:(NSString *)path forKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:key];
}

- (NSString *)getPath:(NSString *)key
{
    NSString *ret = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    return ret;
}

#pragma mark - UI Action

- (NSArray *)duplicationCheck:(NSString *)value
{
    PyObject *object = PyObject_CallMethod(_stringCheck,"duplicationCheck", "(s)",[value UTF8String]);
    if( object == nil )
        return nil;
    Py_ssize_t len = PyList_Size(object);
    NSMutableArray *list = [NSMutableArray new];
    Py_ssize_t i = 0;
    for (i = 0; i < len; i++) {
        PyObject *objcObject = PyList_GetItem(object, (Py_ssize_t)i);
        if (objcObject != nil) {
            NSString *string = [NSString stringWithCString:PyString_AsString(objcObject) encoding:NSUTF8StringEncoding];
            [list addObject:string];
        }
    }
    return list;
}

- (NSArray *)searchValue:(NSString *)value
{
    PyObject *object = PyObject_CallMethod(_stringCheck,"searchKey", "(s)",[value UTF8String]);
    if( object == nil )
        return nil;
    Py_ssize_t len = PyList_Size(object);
    NSMutableArray *list = [NSMutableArray new];
    Py_ssize_t i = 0;
    for (i = 0; i < len; i++) {
        PyObject *objcObject = PyList_GetItem(object, (Py_ssize_t)i);
        if (objcObject != nil) {
            NSString *string = [NSString stringWithCString:PyString_AsString(objcObject) encoding:NSUTF8StringEncoding];
            [list addObject:string];
        }
    }
    return list;
}

- (NSArray *)parseValue:(NSString *)value
{
    NSArray *parseArr = [value componentsSeparatedByString:@"@#$"];
    if( parseArr.count > 2 ){
        NSMutableArray *retArr = [NSMutableArray new];
        [retArr addObject:parseArr[0]];
        NSString *second = parseArr[1];
        [retArr addObjectsFromArray:[second componentsSeparatedByString:@":"]];
        [retArr addObject:parseArr[2]];
        return retArr;
    }
    return nil;;
}

- (IBAction)submitButton:(id)sender
{
    [_nonDuplicateCheck setState:NO];
    if( _classTextField.stringValue != nil && _keywordTextField.stringValue != nil && _valueTextField.stringValue != nil ){
        LStringObject *object = [LStringObject new];
        object.name = _classTextField.stringValue;
        object.key  = _keywordTextField.stringValue;
        object.value= _valueTextField.stringValue;
        [self insertLString:object];
    }
}

- (IBAction)insertAllButton:(id)sender
{
    if( _resultArr.count > 0 ){
        for( id object in _resultArr ){
            if( [object isKindOfClass:[LStringObject class]]){
                LStringObject *lsObject = object;
                if( lsObject.insert )
                    [self writeLString:object];
            }
        }
    }
}

- (void)
duplicateCheck
{
    if (_nonDuplicateCheck.state == NO)
        return;
    NSLog(@"%@",_valueTextField.stringValue);
    if( _valueTextField.stringValue.length > 0 ){
        [_resultArr removeAllObjects];
        if( _nonSearchDuplicateCheck.state == NO ){
            NSArray *duplicateList = [self duplicationCheck:_valueTextField.stringValue];
            if( duplicateList.count > 0 )
                [_resultArr addObject:@"중복 문자열"];
            for( NSString *value in duplicateList )
            {
                NSArray *array = [self parseValue:value];
                if( array != nil && array.count == 5){
                    LStringObject *object = [LStringObject new];
                    object.lang = array[0];
                    object.line = array[1];
                    object.name = array[2];
                    object.key  = array[3];
                    object.value= array[4];
                    [_resultArr addObject:object];
                }
            }
        }
        NSArray *searchArr = [self searchValue:_valueTextField.stringValue];
        if(  searchArr.count > 0 )
            [_resultArr addObject:@"유사 문자열"];
        for( NSString *value in searchArr )
        {
            NSArray *array = [self parseValue:value];
            if( array != nil && array.count == 5){
                LStringObject *object = [LStringObject new];
                object.lang = array[0];
                object.line = array[1];
                object.name = array[2];
                object.key  = array[3];
                object.value= array[4];
                [_resultArr addObject:object];
            }
        }
        [_resultTable reloadData];
    }
}

#pragma mark - NSTextField delegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor;
{
    if( control == _valueTextField )
        [self duplicateCheck];
    return YES;
}

#pragma mark - NSTableView datasource & delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_resultArr count];
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    id Object = [_resultArr objectAtIndex:row];
    if( [Object isKindOfClass:[NSString class]] )
        return YES;
    return NO;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id object = [_resultArr objectAtIndex:row];
    if( [object isKindOfClass:[NSString class]] ){
        if( [tableColumn.identifier isEqualToString:@"value"] )
            return object;
        return @"";
    }else if( [object isKindOfClass:[LStringObject class]]){
        LStringObject *lsObject = object;
        if( [tableColumn.identifier isEqualToString:@"lang"] )
            return lsObject.lang;
        if( [tableColumn.identifier isEqualToString:@"line"] )
            return lsObject.line;
        if( [tableColumn.identifier isEqualToString:@"name"] )
            return lsObject.name;
        if( [tableColumn.identifier isEqualToString:@"keyword"] )
            return lsObject.key;
        if( [tableColumn.identifier isEqualToString:@"value"] )
            return lsObject.value;
        return @"??";
    }
    return nil;
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTextFieldCell *cell = [tableColumn dataCell];
    [cell setTextColor: [NSColor blackColor]];
    id object = [_resultArr objectAtIndex:row];
    if( [object isKindOfClass:[NSString class]] ){
    }else if( [object isKindOfClass:[LStringObject class]]){
        LStringObject *lsObject = object;
        if( lsObject.insert )
            [cell setTextColor: [NSColor redColor]];
    }
    
    return cell;
}


- (void)tableView:(NSTableView *)tableView didClickedRow:(NSInteger)row
{
//    NSLog(@"Click row : %ld",row);
}

- (void)tableView:(NSTableView *)tableView didRightClick:(NSInteger)row withEvent:(NSEvent *)theEvent
{
    NSLog(@"Right Click row : %ld",row);
    _clickRow = row;
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Contextual Menu"];
    [theMenu insertItemWithTitle:@"문자열 복사" action:@selector(CopyString) keyEquivalent:@"" atIndex:0];
    [theMenu insertItemWithTitle:@"중복 문자열 생성( GS String )" action:@selector(GenerateGSString) keyEquivalent:@"" atIndex:1];
    
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:tableView];

}

#pragma mark - alert

- (void)showGSAlert
{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"같은 문자열을 사용하는 경우\n중복 문자열을 생성해주세요.";
    [alert runModal];
}

#pragma mark - table context menu

- (void)CopyString
{
    if( _clickRow < _resultArr.count ){
        id object = [_resultArr objectAtIndex:_clickRow];
        if( [object isKindOfClass:[LStringObject class]]){
            LStringObject *lsObject = object;
            if( [lsObject.value rangeOfString:@"@GS:"].length > 0 )
                _valueTextField.stringValue = lsObject.value;
            else{
                [self showGSAlert];
            }
        }
    }
}

- (void)GenerateGSString
{

}

- (void)test
{
    PyObject_CallMethod(_stringCheck,"loadString",NULL);
    PyObject_CallMethod(_stringCheck,"set_name", "(s)", "charly"); // c.set_name("charly")
    PyObject_CallMethod(_stringCheck,"print_family", "(ssi)", "jack", "cathy", 4); // c.print_family("jack", "cathy", 4)
    
    PyObject *is_asleep = PyObject_CallMethod(_stringCheck,"is_asleep",NULL); // c.is_asleep()
    BOOL isAsleep = (Py_True == is_asleep);
    Py_DECREF(is_asleep);
    NSLog(@"%d", isAsleep);
    
    PyObject *name = PyObject_CallMethod(_stringCheck,"name",NULL); // c.name()
    NSString *catName = [NSString stringWithCString:PyString_AsString(name) encoding:NSASCIIStringEncoding];
    Py_DECREF(name);
    NSLog(@"%@", catName);
}

//
//- (IBAction)action:(id)sender
//{
//    PyObject *name = PyObject_CallMethod(cat,"name",NULL); // c.name()
//    NSString *catName = [NSString stringWithCString: PyString_AsString(name)];
//    Py_DECREF(name);
//    
//    [textField setStringValue:catName];
//}


@end
