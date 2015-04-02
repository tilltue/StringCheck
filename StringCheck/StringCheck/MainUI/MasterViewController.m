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

@interface DuplicateObject : NSObject
@property (nonatomic, strong) NSString *lang;
@property (nonatomic, strong) NSString *line;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@end

@implementation DuplicateObject
@end

@interface SearchObject : NSObject
@property (nonatomic, strong) NSString *lang;
@property (nonatomic, strong) NSString *line;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *value;
@end

@implementation SearchObject
@end

@interface MasterViewController () <DropDelegate,NSTableViewDataSource,NSTableViewDelegate>
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
    
    IBOutlet NSTableView *_resultTable;
    
    NSMutableArray *_resultArr;
}
@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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

- (IBAction)submitButton:(id)sender
{
    NSLog(@"%@",_valueTextField.stringValue);
    if( _valueTextField.stringValue.length > 0 ){
        [_resultArr removeAllObjects];
        NSArray *duplicateList = [self duplicationCheck:_valueTextField.stringValue];
        if( duplicateList.count > 0 ){
            
        }
        NSArray *searchArr = [self searchValue:_valueTextField.stringValue];
        if( searchArr.count > 0 ){
            
        }
        [_resultTable reloadData];
    }
}

#pragma mark - NSTableView datasource & delegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_resultArr count];
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    BOOL isGroup= NO;
    return isGroup;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return nil;
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
