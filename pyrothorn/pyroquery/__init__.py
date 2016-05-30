import logging
import sys, os
testdir = os.path.dirname(__file__)
sys.path.insert(0, os.path.dirname(__file__))

try:
    import pyrothorn.pyroquery.firethorn_config
    import pyrothorn.pyroquery.firethornEngine
    import pyrothorn.pyroquery.queryEngine
    import pyrothorn.pyroquery.voQuery
except Exception as e:
    print "Error during pyrothorn imports..(__init__.py): " + str(e)
    logging.exception(e)
