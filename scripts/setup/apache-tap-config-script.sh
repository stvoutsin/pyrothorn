cat >> /etc/apache2/apache2.conf <<EOF

# mod_proxy setup.
ProxyRequests Off
ProxyPreserveHost On

ProxyPassMatch ^/firethorn\/adql\/table\/(.*)\/votable$    http://${gillianip:?}:8080/firethorn/adql/table/\$1/votable retry=0 connectiontimeout=14400 timeout=14400
ProxyPassReverse  ^/firethorn\/adql\/table\/(.*)\/votable$ http://${gillianip:?}:8080/firethorn/adql/table/\$1/votable

ProxyPassMatch ^/firethorn\/tap\/atlasdr1\/(.*)$  http://${gillianip:?}:8080/firethorn/tap/${tapserviceid:?}/\$1 retry=0 connectiontimeout=14400 timeout=14400
ProxyPassReverse  ^/firethorn\/tap\/atlasdr1\/(.*)$  http://${gillianip:?}:8080/firethorn/tap/${tapserviceid:?}/\$1

ProxyPassMatch ^/firethorn\/tap\/(.*)$  http://${gillianip:?}:8080/firethorn/tap/\$1  retry=0 connectiontimeout=14400 timeout=14400
ProxyPassReverse  ^/firethorn\/tap\/(.*)$  http://${gillianip:?}:8080/firethorn/tap/\$1


<Proxy *>
Order deny,allow
Allow from all
</Proxy>

<Location "/firethorn">
# Configurations specific to this location. Add what you need.
# For instance, you can add mod_proxy_html directives to fix
# links in the HTML code. See link at end of this page about using
# mod_proxy_html.

# Allow access to this proxied URL location for everyone.
Order allow,deny
Allow from all
</Location>
EOF

sudo service apache2 reload
