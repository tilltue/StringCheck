#!/usr/bin/python
class StringCheck:
    
    __name = None
    
    def loadString(self):
        print "meow"
    
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

if __name__ == "__main__":
    _stringCheck = StringCheck()
    _stringCheck.loadString()
    _stringCheck.set_name("charly")
    _stringCheck.print_family("jack", "cathy", 4)
    print c.name()
    print c.is_asleep()