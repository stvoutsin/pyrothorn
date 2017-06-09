FROM firethorn/pythonlibs
MAINTAINER Stelios Voutsinas <stv@roe.ac.uk>

RUN apt-get -y update
RUN apt-get -y upgrade

# Install apache, PHP, and supplimentary programs.
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install apache2 curl libapache2-mod-proxy-html 
# Enable apache mods.
RUN a2enmod rewrite


RUN a2enmod proxy
RUN a2enmod proxy_http


RUN apt-get -y install libapache2-mod-wsgi
RUN a2enmod wsgi


# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV TERM xterm

EXPOSE 80

# Update the default apache site with the config we created.
ADD apache-config.conf /etc/apache2/sites-enabled/000-default.conf

# By default, simply start apache.
CMD /usr/sbin/apache2ctl -D FOREGROUND
