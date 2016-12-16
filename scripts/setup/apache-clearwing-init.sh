chmod 755 -R /var/www/html/app/static/*
chmod 775 /var/www/html/app/sessions
chmod 755 -R /var/www/html/app/log/*
chown www-data:994 /var/www/html/app/log/
chown www-data:994 /var/www/html/app/static/static_vo_tool/temp/

service apache2 reload
