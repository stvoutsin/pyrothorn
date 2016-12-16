chmod 755 -R /var/www/html/atlas/static/*
chmod 755 /var/www/html/atlas/sessions
chmod 755 -R /var/www/html/atlas/log/*
chown www-data:994 /var/www/html/atlas/log/
chown www-data:994 /var/www/html/atlas/static/static_vo_tool/temp/

service apache2 reload
