cat >> /etc/apache2/sites-enabled/000-default.conf <<EOF

<VirtualHost *:80>
    ServerName osa.metagrid.xyz

    ProxyRequests Off
    ProxyPreserveHost On

    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>

    ProxyPass ^/(.*)$  http://${clearwingip:?}/$1
    ProxyPassMatch ^/(.*)$  http://${clearwingip:?}/$1  retry=0 connectiontimeout=14400 timeout=14400
    ProxyPassReverse  ^/(.*)$  http://${clearwingip:?}/$1
</VirtualHost>


<VirtualHost *:80>
    ServerName genius.metagrid.xyz

    ProxyRequests Off
    ProxyPreserveHost On

    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>

    ProxyPass ^/(.*)$  http://${tapserviceip:?}/$1
    ProxyPassMatch ^/(.*)$  http://${tapserviceip:?}/$1  retry=0 connectiontimeout=14400 timeout=14400
    ProxyPassReverse  ^/(.*)$  http://${tapserviceip:?}/$1

</VirtualHost>


EOF

sudo service apache2 reload
