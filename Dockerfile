FROM firethorn/pythonlibs
MAINTAINER Stelios Voutsinas <stv@roe.ac.uk>

RUN mkdir /home/pyrothorn
COPY . /home/pyrothorn/
COPY /conf/odbcinst.ini /etc/
#RUN home/pyrothorn/testing/test_firethorn_logged_sql.py
