import logging
import sys, os
testdir = os.path.dirname(__file__)
sys.path.insert(0, os.path.dirname(__file__))

try:
    import firethorn_config
    import firethornEngine
    import queryEngine
    import voQuery
except Exception as e:
    print "Error during pyrothorn imports..(__init__.py): " + str(e)
    logging.exception(e)
