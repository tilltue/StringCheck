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
    _localizationDictArr = []
    #wb = Workbook()
    #ws = wb.active
    #ws['A1'] = 42
    #ws.append([1,2,3])
    #import datetime
    #ws['A2'] = datetime.datetime.now()
    #wb.save("sample.xlsx")
    
    #print(sheetTap_android['C1'].value)
    
    def makeArr(self, wb, tapname, array):
        print "make" + tapname
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
    
    def duplicationCheck(self, value):
        print 'check : ' + value
        retArr = []
        for dictionary in self._localizationDictArr:
            index = self._localizationDictArr.index(dictionary)
            lang = self._localizationPathArr[index]
            lang = lang[lang.find('Resources/')+10:lang.rfind('.lproj')]
            for key, val in dictionary.items():
                if val == value:
                    retArr.append(lang+'@#$'+key+'@#$'+val)
        #print 'len' + str(len(retArr))
        return retArr

    def searchKey(self, searchKey):
        print 'search : ' + searchKey
        retArr = []
        for dictionary in self._localizationDictArr:
            index = self._localizationDictArr.index(dictionary)
            lang = self._localizationPathArr[index]
            lang = lang[lang.find('Resources/')+10:lang.rfind('.lproj')]
            for key, val in dictionary.items():
                if val.find(searchKey) > 0 :
                    retArr.append(lang+'@#$'+key+'@#$'+val)
        #print 'len' + str(len(retArr))
        return retArr
    
    
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
    
    def getDictionaryInLSFile(self, filePath):
        dictionary = {}
        f = open(filePath, 'r')
        i = 0
        while 1:
            i+=1
            line = f.readline()
            range = line.find('=')
            key = str(i)
            if range > 0:
                keyword = line[1:range-1]
                value = line[range+2:-3]
                dictionary[key+':'+keyword] = value
            else :
                dictionary[key+':empty'] = 'empty'
            if not line: break
        f.close()
        return dictionary

    def loadLocalString(self, filePath):
        for filename in os.listdir(filePath):
            if filename.find('lproj') > 0 :
                for lsPath in os.listdir(filePath+'/'+filename):
                    if lsPath.find('strings') > 0 :
                        self._localizationPathArr.append(filePath+'/'+filename+'/'+lsPath)
        for path in self._localizationPathArr:
            print path
            dictionary = self.getDictionaryInLSFile(path)
            self._localizationDictArr.append(dictionary)

if __name__ == "__main__":
    _stringCheck = StringCheck()
    #_stringCheck.loadString()
    _stringCheck.set_name("charly")
    _stringCheck.print_family("jack", "cathy", 4)
    print _stringCheck.name()
    print _stringCheck.is_asleep()


