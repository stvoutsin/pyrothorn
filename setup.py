import os
from setuptools import setup

# Utility function to read the README file.
# Used for the long_description.  It's nice, because now 1) we have a top level
# README file and 2) it's easier to type in the README file than to put a raw
# string in below ...
def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(
    name = "pyrothorn",
    version = "0.0.1",
    author = "Stelios Voutsinas",
    author_email = "stv@roe.ac.uk",
    description = ("A python testing suite for firethorn, and vo services (TAP)"),
    license = "BSD",
    keywords = "pyrothorn firethorn vo",
    url = "http://wfau.metagrid.co.uk/code/firethorn",
    packages=['pyrothorn', 'pyrothorn.pyroquery', 'pyrothorn.mssql', 'pyrothorn.misc', 'pyrothorn.generators'],
    tests_require=['selenium'],
    install_requires=['selenium'],
    long_description=read('README'),
    classifiers=[
        "Development Status :: 1 - Alpha",
        "Topic :: Utilities",
        "License :: GPL License",
    ],
)

