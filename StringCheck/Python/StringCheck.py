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
    
    def writeFile(self,path,line,string,sameClass):
        f = open(path,'r')
        lines = f.readlines()
        f.close()
        
        if sameClass == 0 :
            print 'sametest' + str(line)
            lines.insert(int(line)-1,string)
        else :
            if lines[int(line)-1] != '\n':
                lines.insert(int(line),'\n')
                lines.insert(int(line)+1,string)
            else:
                lines.insert(int(line),string)
        f = open(path,'w')
        f.writelines(lines)
        f.close()
    
    def writeLocalString(self, line, lang, name, keyword, value, sameClass):
        writeString = '"' + name + ':' + keyword + '"="' + value + '";\n'
        #print str(line) + writeString
        for dictionary in self._localizationDictArr:
            index = self._localizationDictArr.index(dictionary)
            LSpath = self._localizationPathArr[index]
            langName = LSpath[LSpath.find('Resources/')+10:LSpath.rfind('.lproj')]
            if langName != lang:
                continue
            self.writeFile(LSpath,line,writeString,sameClass)


    
    def searchPrefix(self, name, searchName, maxSearchLen):
        lowerName = name.lower()
        lowerSearchName = searchName.lower()
        if len(lowerSearchName) < 3 or len(lowerSearchName) < maxSearchLen :
            return -1
        if lowerName.find(lowerSearchName[:1]) < 0 :
            return -1
        location = lowerName.find(lowerSearchName)
        #print 'step1 ' + searchName + ' : ' + name + ': ' + str(location)
        if location == 0 :
            #print 'searchName : ' + searchName
            return len(searchName)
        else :
            return self.searchPrefix(name,searchName[:-1],maxSearchLen)
    
    def insertCheck(self, name, keyword, value):
        print 'insert : ' + name
        retArr = []
        for dictionary in self._localizationDictArr:
            searchClassName = ''
            searchMax = -1
            lineMax = -1
            lastLine = -1
            index = self._localizationDictArr.index(dictionary)
            lang = self._localizationPathArr[index]
            lang = lang[lang.find('Resources/')+10:lang.rfind('.lproj')]
            sameFind = 0
            for key, val in dictionary.items():
                className = key[key.find(':')+1:key.rfind(':')]
                line = key[:key.find(':')]
                if int(lastLine) < int(line):
                    lastLine = line
                if len(className) == 0:
                    continue
                if className == name:
                    sameFind = 1
                    if line > lineMax :
                        searchClassName = lang+'@#$'+key+'@#$'+val
                        lineMax = line
                    continue
                elif sameFind == 0 :
                    searchLength = self.searchPrefix(className,name,searchMax)
                    if searchLength < 0 :
                        continue
                    #print str(searchLength)
                    if searchLength == searchMax and line > lineMax :
                        lineMax = line
                        searchClassName = lang+'@#$'+key+'@#$'+val
                    if searchLength > searchMax :
                        searchClassName = lang+'@#$'+key+'@#$'+val
                        searchMax = searchLength
            if len(searchClassName) > 0 :
                retArr.append(searchClassName)
            else:
                retArr.append(lang+'@#$'+str(lastLine)+': : '+'@#$'+'lastLine')
        return retArr
    
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
    
    def insertString(self, name, keyword, value):
        print name + keyword + value
        return self.insertCheck(name, keyword, value)
    
    
    def getValue(self,line):
        start = line.find("\"")
        end = line.rfind("\"")
        return line[start+1:end]
    
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
                keyword = self.getValue(line[:range])
                value = self.getValue(line[range+1:])
                dictionary[key+':'+keyword] = value
            else :
                dictionary[key+':empty'] = 'empty'
            if not line: break
        f.close()
        return dictionary

    def loadLocalString(self, filePath):
        for filename in os.listdir(filePath):
            if filename.find('lproj') > 0 :
                if filename.find('zh-Hant') > 0 :
                    continue
                for lsPath in os.listdir(filePath+'/'+filename):
                    if lsPath.find('strings') > 0 :
                        self._localizationPathArr.append(filePath+'/'+filename+'/'+lsPath)
        for path in self._localizationPathArr:
            if path.find('zh-Hant') > 0 :
                continue
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


