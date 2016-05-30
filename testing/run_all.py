import os
import glob
import sys


tests = glob.glob('test*.py')
for test in tests:
    os.system('python %s' % test)
