"""
misc module

Miscellaneous functions used by for freeform SQL query processing for use with TAP services and XML VOTable procesing

Created on Nov 30, 2011
@author: stelios
"""

import os
import urllib2
import urllib
import time
import xml.dom.minidom
import pyodbc
try:
    import simplejson as json
except ImportError:
    import json
import numpy
import re
import logging
import datetime
from time import gmtime,  strftime
from astropy.table import Table
from cStringIO import StringIO

class VOQuery():
    """
    Run a ADQL/TAP query, does an asynchronous TAP job behind the scene
    """
    def __init__(self, endpointURL, query, mode_local="async", request="doQuery", lang="ADQL", voformat="votable", maxrec=None):
        self.endpointURL = endpointURL
        self.query, self.lang = query, lang
        self.mode_local = mode_local
        self.voformat = voformat
        self.request = request
        self.maxrec = maxrec
        self.votable = None


    @property
    def votable(self):
        """Votable object"""
        return self.votable


    def run(self):
        """
        Run the query
        Todo: Add synchronous query capability
        """
        self.votable = self.execute_async_query(self.endpointURL, self.query, self.mode_local, self.request, self.lang, self.voformat, self.maxrec)


    def _get_async_results(self, endpointURL, extension):
        """
        Open the given url and extension and read/return the result

        @param endpointURL: A URL string to open
        @param extension: An extension string to attach to the URL request
        @return: The result of the HTTP request sent to the the URL
        """

        res = ''
        f = ''
        try:
            req = urllib2.Request(endpointURL + extension)
            f = urllib2.urlopen(req)
            res =  f.read()
            f.close()
        except Exception as e:
            if f!='':
                f.close()
            logging.exception(e)

        return res


    def _start_async_loop(self, url):
        """
        Takes a TAP url and starts a loop that checks the phase URI and returns the results when completed. The loop is repeated every [delay=3] seconds

        @param url: A URL string to be used
        @return: A Votable with the results of a TAP job, or '' if error
        """

        return_vot = []
        try:
            while True:
                res = self._get_async_results(url,'/phase')
                if res=='COMPLETED':
                    return_vot = Table.read(StringIO(self._get_async_results(url,'/results/result')), format="votable")
                    break
                elif res=='ERROR' or res== '':
                    return None
                time.sleep(1)
        except Exception as e:
            logging.exception(e)
            return None

        return return_vot
	

    def get_votable_rowcount(self):
        """
        Get table rowcount
        """
        if self.votable:
            return len(self.votable)
        else :
            return -1

    def execute_async_query(self, url, q, mode_local="async", request="doQuery", lang="ADQL", voformat="votable", maxrec=None):
        """
        Execute an ADQL query (q) against a TAP service (url + mode:sync|async)
        Starts by submitting a request for an async query, then uses the received job URL to call start_async_loop, to receive the final query results

        @param url: A string containing the TAP URL
        @param mode: sync or async to determine TAP mode of execution
        @param q: The ADQL Query to execute as string

        @return: Return a votable with the results, the TAP job ID and a temporary file path with the results stored on the server
        """

        if (maxrec!=None):
            params = urllib.urlencode({'REQUEST': request, 'LANG': lang, 'FORMAT': voformat, 'QUERY' : q, 'MAXREC' : maxrec})
        else:
            params = urllib.urlencode({'REQUEST': request, 'LANG': lang, 'FORMAT': voformat, 'QUERY' : q})

        full_url = url+"/"+mode_local

        votable = []
        jobId= 'None'
        file_path=''
        try:
            #Submit job and get job id
            req = urllib2.Request(full_url, params)
            opener = urllib2.build_opener()

            f = opener.open(req)
            jobId = f.url
            logging.info("Jobid:" + jobId)
            #Execute job and start loop requests for results
            req2 = urllib2.Request(jobId+'/phase',urllib.urlencode({'PHASE' : 'RUN'}))
            f2 = opener.open(req2) #@UnusedVariable

            # Return results as a votable object
            votable = self._start_async_loop(jobId)


        except Exception as e:
            logging.exception(e)
            return None

        return votable



