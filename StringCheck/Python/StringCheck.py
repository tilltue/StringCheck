#!/usr/bin/python

import sys
import os
from openpyxl import Workbook
from openpyxl import load_workbook

class StringCheck:
    
    __name = None
    _androidStringArr = []
    _iosStringArr = []
    _localizationPathArr = []
    #wb = Workbook()
    #ws = wb.active
    #ws['A1'] = 42
    #ws.append([1,2,3])
    #import datetime
    #ws['A2'] = datetime.datetime.now()
    #wb.save("sample.xlsx")
    
    #print(sheetTap_android['C1'].value)
    
    def makeArr(self, wb, tapname, array):
        print "make arr"
        sheetTap = wb[tapname]
        rowCount = 0;
        for row in sheetTap.rows:
            array.append([])
            for cell in row:
                if cell.value != None:
                    array[rowCount].append(cell.value);
            rowCount+=1
        print len(array)
    
    def loadString(self, filePath):
        print filePath
        _wb = load_workbook(filename = filePath, read_only=True)
        self.makeArr(_wb,'Android-New',self._androidStringArr)
        self.makeArr(_wb,'iOS-New',self._iosStringArr)
        print "loadString"
    
    def set_name(self, name):
        self.__name = name
    
    def name(self):
        return self.__name
    
    def print_family(self, father, mother, nb_bros_sisters):
        print "father is " + father
        print "mother is " + mother
        print "%d brothers and sisters" % nb_bros_sisters
    
    def is_asleep(self):
        return True

    def loadLocalString(self, filePath):
        #print filePath
        for filename in os.listdir(filePath):
            if filename.find('lproj') > 0 :
                for lsPath in os.listdir(filePath+'/'+filename):
                    if lsPath.find('strings') > 0 :
                        self._localizationPathArr.append(filePath+'/'+filename+'/'+lsPath)
        for path in self._localizationPathArr:
            print path

if __name__ == "__main__":
    _stringCheck = StringCheck()
    #_stringCheck.loadString()
    _stringCheck.set_name("charly")
    _stringCheck.print_family("jack", "cathy", 4)
    print _stringCheck.name()
    print _stringCheck.is_asleep()


