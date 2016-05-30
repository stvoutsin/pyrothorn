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
This file contains a contains the high-level functions to read a
VOTable file.
"""

from __future__ import division, absolute_import

# LOCAL
from . import tree
from . import util
from . import xmlutil

def parse(source, columns=None, invalid='exception', pedantic=True,
          chunk_size=tree.DEFAULT_CHUNK_SIZE, table_number=None,
          filename=None,
          _debug_python_based_parser=False):
    """
    Parses a VOTABLE xml file (or file-like object), and returns a
    :class:`~vo.tree.VOTable` object, with a nested list of
    :class:`~vo.tree.Resource` instances and :class:`~vo.tree.Table`
    instances.

    *source* may be a filename or a readable file-like object.

    If the *columns* parameter is specified, it should be a list of
    field names to include in the output.  The default is to include
    all fields.

    The *invalid* parameter may be one of the following values:

      - 'exception': throw an exception when an invalid value is
        encountered (default)

      - 'mask': mask out invalid values

    When *pedantic* is True, raise an error when the file violates the
    spec, otherwise issue a warning.  Warnings may be controlled using
    the standard Python mechanisms.  See the :mod:`warnings` module in
    the Python standard library for more information.

    *chunk_size* is the number of rows to read before converting to an
    array.  Higher numbers are likely to be faster, but will consume
    more memory.

    *table_number* is the number of table in the file to read in.  If
    `None`, all tables will be read.  If a number, 0 refers to the
    first table in the file.

    *filename* is a filename, URL or other identifier to use in error
    messages.  If *filename* is None and *source* is a string (i.e. a
    path), then *source* will be used as a filename for error
    messages.
    """
    

    invalid = invalid.lower()
    assert invalid in ('exception', 'mask')

    config = {
        'columns':      columns,
        'invalid':      invalid,
        'pedantic':     pedantic,
        'chunk_size':   chunk_size,
        'table_number': table_number,
        'filename':     filename
        }

    if filename is None and isinstance(source, basestring):
        config['filename'] = source

    source = util.convert_to_fd_or_read_function(source)

    iterator = xmlutil.get_xml_iterator(
        source, _debug_python_based_parser=_debug_python_based_parser)

    return tree.VOTableFile(config=config, pos=(1, 1)).parse(iterator, config)


def parse_single_table(source, **kwargs):
    """
    Parses a VOTABLE xml file (or file-like object), assuming it only
    contains a single TABLE element, and returns a
    :class:`~vo.tree.Table` instance.

    See :func:`parse` for a description of the keyword arguments.
    """
    if kwargs.get('table_number') is None:
        kwargs['table_number'] = 0

    votable = parse(source, **kwargs)

    return votable.get_first_table()
