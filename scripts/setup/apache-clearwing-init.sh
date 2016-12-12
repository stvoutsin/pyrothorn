chmod 775 -R /var/www/html/atlas/static/*
chmod 775 /var/www/html/atlas/sessions
chmod 775 -R /var/www/html/atlas/log/*
chown www-data:994 access.log
chown www-data:994 error.log

service apache2 reload
