# Copyright (C) 2008-2010 Association of Universities for Research in Astronomy (AURA)

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

#     1. Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.

#     2. Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.

#     3. The name of AURA and its representatives may not be used to
#       endorse or promote products derived from this software without
#       specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY AURA ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL AURA BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
# OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
# USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.

"""
Common utilities for accessing VO simple services.
"""

# TODO docstrings

from __future__ import division, absolute_import

# STDLIB
import codecs
import random
import sys
import warnings
if sys.hexversion < 0x02060000:
    from vo.lib import simplejson as json
else:
    import json
if sys.hexversion >= 0x03000000:
    import io

# LOCAL
from . import cache
from . import table
from . import util
from .util import IS_PY3K
from . import webquery
from .voexceptions import vo_warn, W24, W25

BASEURL = 'http://stsdas.stsci.edu/astrolib/vo_databases/'
db_cache = cache.Cache('~/.vodb', BASEURL)

__dbversion__ = 1

_doc_snippets = {
    'pedantic' :
    """*pedantic* has the same meaning as :func:`~vo.table.parse`.
    When *pedantic* is True, raise an error when the returned VOTable
    file violates the spec, otherwise issue a warning.  Warnings may
    be controlled using the standard Python mechanisms.  See the
    :mod:`warnings` module in the Python standard library for more
    information.""",

    'catalog_db' :
    """*catalog_db* may be one of the following, in order from easiest to
    use to most control:

      - `None`: A database of conesearch catalogs is downloaded from
        STScI.  The first catalog in the database to successfully
        return a result is used.

      - *catalog name*: A name in the database of conesearch catalogs
        at STScI is used.  For a list of acceptable names, see
        :func:`list_catalogs`.

      - *url*: The prefix of a *url* to a IVOA Cone Search Service.
        Must end in either `?` or `&`.

      - A `~vos_catalog.VOSCatalog` instance: A specific catalog
        manually downloaded and selected from the database using the
        APIs in the :mod:`vos_catalog` module.

      - Any of the above 3 options combined in a list, in which case
        they are tried in order."""
}

class VOSCatalog:
    def __init__(self, tree):
        self._tree = tree

    def get_url(self):
        return self._tree['url']

class VOSDatabase:
    def __init__(self, tree):
        self._tree = tree

        if tree['__version__'] > __dbversion__:
            vo_warn(W24)

        if not 'catalogs' in tree:
            raise IOError("Invalid VO service catalog database")
        self._catalogs = tree['catalogs']

    def get_catalogs(self):
        for key, val in self._catalogs.items():
            yield key, VOSCatalog(val)

    def get_catalog(self, name):
        if not name in self._catalogs:
            raise ValueError("No catalog '%s' found." % name)
        return VOSCatalog(self._catalogs[name])

    def list_catalogs(self):
        return self._catalogs.keys()

def get_remote_catalog_db(dbname, cache_instance=db_cache):
    """
    Get a database of VO services (which is a JSON file) from a remote
    location.
    """
    fd = cache_instance.get_file(dbname + ".json")
    if IS_PY3K:
        wrapped_fd = io.TextIOWrapper(fd, 'utf8')
    else:
        wrapped_fd = fd
    try:
        tree = json.load(wrapped_fd)
    finally:
        fd.close()

    return VOSDatabase(tree)

def _vo_service_request(url, pedantic, kwargs):
    req = webquery.webget_open(url, **kwargs)
    try:
        tab = table.parse(req, filename=req.geturl(), pedantic=pedantic)
    finally:
        req.close()

    # In case of errors from the server, a complete and correct
    # "stub" VOTable file may still be returned.  This is to
    # detect that case.
    for param in tab.iter_fields_and_params():
        if param.ID.lower() == 'error':
            raise IOError(
                "Catalog server '%s' returned error '%s'" %
                (url, param.value))
        break

    for info in tab.resources[0].infos:
        if info.name == 'QUERY_STATUS' and info.value != 'OK':
            if info.content is not None:
                long_descr = ':\n%s' % info.content
            else:
                long_descr = ''
            raise IOError(
                "Catalog server '%s' returned status '%s'%s" %
                (url, info.value, long_descr))
        break

    return tab.get_first_table()

def call_vo_service(service_type, catalog_db=None, pedantic=False,
                    verbose=True, kwargs={}):
    """
    Makes a generic VO service call.

    *service_type* is the name of the type of service,
    eg. 'conesearch'.  Used in error messages and to select a catalog
    database if one is not provided.

    %(catalog_db)s

    %(pedantic)s

    *kwargs* is a dictionary of arguments to pass to the catalog
    service.  No checking is done that the arguments are accepted by
    the service etc.
    """
    if catalog_db is None:
        catalog_db = get_remote_catalog_db(service_type)
        catalogs = catalog_db.get_catalogs()
    elif isinstance(catalog_db, (VOSCatalog, basestring)):
        catalogs = [(None, catalog_db)]
    elif isinstance(catalog_db, list):
        for x in catalog_db:
            assert isinstance(
                catalog_db, (VOSCatalog, basestring))
        catalogs = [(None, x) for x in catalog_db]
    elif isinstance(catalog_db, VOSDatabase):
        catalogs = catalog_db.get_catalogs()
    else:
        raise TypeError(
            "catalog_db must be a catalog database, a list of catalogs, or a catalog")

    # # Perform a random ordering of the catalogs -- this is just a dumb
    # # heuristic for now.
    # random.shuffle(catalogs)

    for name, catalog in catalogs:
        if isinstance(catalog, basestring):
            if catalog.startswith("http"):
                url = catalog
            else:
                remote_db = get_remote_catalog_db(service_type)
                catalog = remote_db.get_catalog(catalog)
                url = catalog.get_url()
        else:
            url = catalog.get_url()

        if verbose:
            util.color_print('green', "Trying %s" % url, bold=True)

        try:
            return _vo_service_request(url, pedantic, kwargs)
        except Exception as e:
            vo_warn(W25, (url, str(e)))

    raise IOError("None of the available catalogs returned valid results.")
call_vo_service.__doc__ = call_vo_service.__doc__ % _doc_snippets

def list_catalogs(service_type):
    """
    List the catalogs available for the given service type.
    """
    catalog_db = get_remote_catalog_db(service_type)

    return catalog_db.list_catalogs()
