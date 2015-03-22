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

@interface MasterViewController () <DropDelegate>
{
    PyObject *_stringCheck;
    IBOutlet MDDragDropView *_dragAndDropView;
    IBOutlet NSImageView *_imageView;
}
@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dragAndDropView.dropdelegate = self;
    
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

- (void)parseData:(NSURL *)fileURL
{
    PyObject_CallMethod(_stringCheck,"loadString", "(s)",[[fileURL path] UTF8String]);
}

- (NSImage *)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError
{
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:url];
    if(!image) {
        if(outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
        return nil;
    }
    return image;
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
