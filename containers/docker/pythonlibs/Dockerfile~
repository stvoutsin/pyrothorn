FROM firethorn/python:3.4.2
MAINTAINER Stelios Voutsinas <stv@roe.ac.uk>

# Install Python Libs
RUN apt-get update
RUN apt-get install -y python-numpy python-scipy
RUN apt-get install -y pwgen
RUN apt-get install -y python-pycurl
RUN apt-get install unixodbc-dev
RUN pip install --allow-external pyodbc --allow-unverified pyodbc pyodbc
RUN apt-get -y install python-matplotlib
RUN pip install --no-deps astropy

