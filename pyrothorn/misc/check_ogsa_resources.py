

"""
Check the status of an ogsadai resource
"""


import sys
import time
import urllib2

class OgsaChecker(object):

    ogsapath = "http://timothy:8080/ogsadai/services/dataResources/"

    def __init__(self, ogsaresource=""):
        self.ogsaresource = self.ogsapath + ogsaresource

    def execute_check(self, wait_seconds=30):
        self.get_status_code()
        time.sleep(wait_seconds)
	return

    def get_status_code(self):
        req = urllib2.Request(self.ogsaresource)

        try:
            resp = urllib2.urlopen(req)
        except urllib2.HTTPError as e:
            if e.code == 404:
                print "Error! Resource not found: 404"
            else:
                print "Error! Resource not found:" + e
	    quit()
        except urllib2.URLError as e:
            print "Error! Resource not found: " + e
            quit()
        else:
            # 200
            body = resp.read()
	return

    def start_ogsa_check(self):
        while True:
            self.execute_check()


if __name__ == '__main__':
    print "Starting ogsa resource check.."
    if len(sys.argv)<2:
        print "Please provide an ogsadai resource as a parameter!"
    else:
        ogsaresource = str(sys.argv[1])
        ogschk = OgsaChecker(ogsaresource)
        ogschk.start_ogsa_check()

