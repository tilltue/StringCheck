//
//  MasterViewController.m
//  POStringCheck
//
//  Created by nako on 2015. 3. 22..
//  Copyright (c) 2015년 nako. All rights reserved.
//

#import "MasterViewController.h"
#import <Python/Python.h>

@interface MasterViewController ()
{
    PyObject *cat;
}
@end

@implementation MasterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    Py_Initialize();
    
    PyObject *sysModule = PyImport_ImportModule("sys");
    PyObject *sysModuleDict = PyModule_GetDict(sysModule);
    PyObject *pathObject = PyDict_GetItemString(sysModuleDict, "path");
    
    NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/Contents/Resources"];
    PyObject_CallMethod(pathObject, "insert", "(is)", 0, [bundlePath cStringUsingEncoding:[NSString defaultCStringEncoding]]);
    
    Py_DECREF(sysModule); // borrowed reference
    
    /* import and instantiate Cat */
    PyObject *CatModule = PyImport_ImportModule("Cat");	// from Cat import *
    
    PyObject *Cat = PyDict_GetItemString(PyModule_GetDict(CatModule), "Cat");
    cat = PyObject_CallObject(Cat, NULL); // c = Cat()
    
    Py_DECREF(CatModule);
    Py_DECREF(Cat);
//    [self test];
    [self performSelector:@selector(test) withObject:nil afterDelay:3];
}

- (void)test
{
    /* use Cat instance methods */
    
    PyObject_CallMethod(cat,"scream",NULL); // c.scream()
    PyObject_CallMethod(cat,"set_name", "(s)", "charly"); // c.set_name("charly")
    PyObject_CallMethod(cat,"print_family", "(ssi)", "jack", "cathy", 4); // c.print_family("jack", "cathy", 4)
    
    PyObject *is_asleep = PyObject_CallMethod(cat,"is_asleep",NULL); // c.is_asleep()
    BOOL isAsleep = (Py_True == is_asleep);
    Py_DECREF(is_asleep);
    NSLog(@"%d", isAsleep);
    
    PyObject *name = PyObject_CallMethod(cat,"name",NULL); // c.name()
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
