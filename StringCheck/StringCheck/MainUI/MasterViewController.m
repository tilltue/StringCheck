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
#import "CustomTextField.h"

@interface LStringObject : NSObject
@property (nonatomic, strong) NSString *lang;
@property (nonatomic, strong) NSString *line;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@property (nonatomic, assign) NSInteger translation;
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
    IBOutlet CustomTextField *_textFiledAppStringPath;
    IBOutlet CustomTextField *_textFiledLoStringPath;
    
    IBOutlet CustomTextField *_classTextField;
    IBOutlet CustomTextField *_keywordTextField;
    IBOutlet CustomTextField *_valueTextField;
    IBOutlet CustomTextField *_gskeywordTextField;
    IBOutlet NSButton *_submitButton;
    IBOutlet NSButton *_nonDuplicateCheck;
    IBOutlet NSButton *_automaticCheck;
    IBOutlet NSButton *_nonSearchDuplicateCheck;
    IBOutlet NSButton *_insertAllButton;
    IBOutlet NSButton *_addPrefixButton;
    IBOutlet NSButton *_lastInsertButton;
    IBOutlet NSButton *_translationCheckButton;
    
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
    
    NSString *bundlePath = [[[NSBundle mainBundle]
                             bundlePath] stringByAppendingString:@"/Contents/Resources"];
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

- (void)replaceLString:(LStringObject *)object
{
    NSString *value = object.value;
    PyObject_CallMethod(_stringCheck,"replaceLocalString", "(sssssss)",[object.line UTF8String],[object.lang UTF8String],[object.name UTF8String],[object.key UTF8String],[value UTF8String],
                        (object.sameClass?[@"0" UTF8String]:[@"1" UTF8String]),
                        (_lastInsertButton.state?[@"0" UTF8String]:[@"1" UTF8String])
                        );
}
- (void)writeLString:(LStringObject *)object
{
    NSString *value = object.value;
    if( _addPrefixButton.state && ![object.lang isEqualToString:@"ko"] ){
        value = [NSString stringWithFormat:@"(번)%@",value];
    }
    PyObject_CallMethod(_stringCheck,"writeLocalString", "(sssssss)",[object.line UTF8String],[object.lang UTF8String],[object.name UTF8String],[object.key UTF8String],[value UTF8String],
                        (object.sameClass?[@"0" UTF8String]:[@"1" UTF8String]),
                        (_lastInsertButton.state?[@"0" UTF8String]:[@"1" UTF8String])
                        );
}

- (void)translationCheck
{
    PyObject *pyObject = PyObject_CallMethod(_stringCheck,"translationCheck", "(s)",[@"번)" UTF8String]);
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
            [_resultArr addObject:@"번역된 리소스 목록"];
            _insertAllButton.enabled = YES;
            NSInteger translateCount = 0;
            for( NSString *value in list )
            {
                NSArray *array = [self parseValue:value];
                if( array != nil && array.count == 6){
                    BOOL validTranslationValue = YES;
                    if( [array[5] isEqualToString:@"&&None&&"] )
                        validTranslationValue = NO;
                    if( !validTranslationValue && _translationCheckButton.state )
                        continue;
                    LStringObject *object = [LStringObject new];
                    object.lang = array[0];
                    object.line = array[1];
                    object.name = array[2];
                    object.key  = array[3];
                    object.value= array[4];
                    [_resultArr addObject:object];
                    LStringObject *transObject = [LStringObject new];
                    transObject.lang = array[0];
                    transObject.line = array[1];
                    transObject.name = array[2];
                    transObject.key  = array[3];
                    if( !validTranslationValue ){
                        transObject.value = @"시트에 값이 없음";
                        transObject.translation = 2;
                    }else{
                        transObject.value= array[5];
                        transObject.translation = 1;
                        translateCount+=1;
                    }
                    [_resultArr addObject:transObject];
                }
                _insertAllButton.title = [NSString stringWithFormat:@"모두 적용 (%ld)",translateCount];
            }
            [_resultTable reloadData];
        }else{
            _insertAllButton.enabled = NO;
        }
    }
}

- (void)insertLString:(LStringObject *)object
{
    PyObject *pyObject = nil;
    if( _lastInsertButton.state )
        pyObject = PyObject_CallMethod(_stringCheck,"getLastLine", "(s)",[object.name UTF8String]);
    else
        pyObject = PyObject_CallMethod(_stringCheck,"insertString", "(sss)",[object.name UTF8String],[object.key UTF8String],[object.value UTF8String]);
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
            NSInteger insertCount = 0;
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
                    addObject.sameClass = [[array[2] lowercaseString] isEqualToString:[_classTextField.stringValue lowercaseString]];
                    addObject.lang = array[0];
                    addObject.line = [NSString stringWithFormat:@"%d",[array[1] intValue] + 1];
                    addObject.name = addObject.sameClass?object.name:_classTextField.stringValue;
                    addObject.key  = _keywordTextField.stringValue;
                    addObject.value= _valueTextField.stringValue;
                    addObject.insert = YES;
                    if( [object.lang isEqualToString:addObject.lang] && [object.name isEqualToString:addObject.name] && [object.key isEqualToString:addObject.key] ){
                        addObject.insert = NO;
                        addObject.value = @"해당 키가 이미 존재합니다";
                    }
                    if( addObject.insert )
                        insertCount+=1;
                    [_resultArr addObject:addObject];
                }
                _insertAllButton.title = [NSString stringWithFormat:@"insert All (%ld)",insertCount];
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
        if( parseArr.count > 3 )
            [retArr addObject:parseArr[3]];
        return retArr;
    }
    return nil;;
}

- (IBAction)translationButton:(id)sender
{
    [self translationCheck];
}

- (IBAction)submitButton:(id)sender
{
    [_nonDuplicateCheck setState:NO];
    if( _classTextField.stringValue.length > 0  && _keywordTextField.stringValue.length > 0 && _valueTextField.stringValue.length > 0 ){
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
                if( lsObject.translation == 1)
                    [self replaceLString:object];
            }
        }
        [_resultArr removeAllObjects];
        [_resultTable reloadData];
        _insertAllButton.enabled = NO;
    }
}

- (IBAction)duplicateButton:(id)sender
{
    _nonDuplicateCheck.state = YES;
    [self duplicateCheck];
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
        if( lsObject.translation == 1)
            [cell setTextColor: [NSColor blueColor]];
        else if( lsObject.translation == 2)
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
    [theMenu insertItemWithTitle:@"선택한 문자열 번역 적용" action:@selector(selectedTranslationString) keyEquivalent:@"" atIndex:0];
    [theMenu insertItemWithTitle:@"선택한 문자열 삽입" action:@selector(selectedInsertString) keyEquivalent:@"" atIndex:1];
    [theMenu insertItemWithTitle:@"문자열 복사" action:@selector(CopyString) keyEquivalent:@"" atIndex:2];
    [theMenu insertItemWithTitle:@"중복 문자열 생성( GS String )" action:@selector(GenerateGSString) keyEquivalent:@"" atIndex:3];
    
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:tableView];

}

#pragma mark - alert

- (void)showGSAlert
{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"같은 문자열을 사용하는 경우\n중복 문자열을 생성해주세요.";
    [alert runModal];
}

- (void)showDuplicateKeyAlert
{
    NSAlert *alert = [NSAlert new];
    alert.messageText = @"이미 해당 키값이 존재합니다.";
    [alert runModal];
}


#pragma mark - table context menu

- (void)
selectedTranslationString
{
    NSIndexSet *_selectedRows = [_resultTable selectedRowIndexes];
    if( _selectedRows.count > 0 ){
        [_selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            id object = [_resultArr objectAtIndex:idx];
            if( [object isKindOfClass:[LStringObject class]]){
                LStringObject *lsObject = object;
                if( lsObject.translation == 1)
                    [self replaceLString:object];
            }
        }];
        [_resultArr removeAllObjects];
        [_resultTable reloadData];
        _insertAllButton.enabled = NO;
    }
}

- (void)
selectedInsertString
{
    NSIndexSet *_selectedRows = [_resultTable selectedRowIndexes];
    if( _selectedRows.count > 0 ){
        [_selectedRows enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            id object = [_resultArr objectAtIndex:idx];
            if( [object isKindOfClass:[LStringObject class]]){
                LStringObject *lsObject = object;
                if( lsObject.insert )
                    [self writeLString:object];
            }
        }];
        [_resultArr removeAllObjects];
        [_resultTable reloadData];
        _insertAllButton.enabled = NO;
    }
}

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
