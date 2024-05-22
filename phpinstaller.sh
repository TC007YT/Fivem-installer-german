#!/bin/bash

# PHPMyAdmin Installer Skript
# Dieses Skript installiert PHPMyAdmin auf einem Ubuntu-System

# Überprüfen, ob das Skript als root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
  echo "Dieses Skript muss als root ausgeführt werden" >&2
  exit 1
fi

# Update und Upgrade des Systems
echo "System wird aktualisiert..."
apt-get update -y
apt-get upgrade -y

# Installation der erforderlichen Pakete
echo "Erforderliche Pakete werden installiert..."
apt-get install -y apache2 php php-mbstring php-zip php-gd php-json php-curl php-cli php-xml mariadb-server mariadb-client wget unzip

# Starten und Aktivieren von Apache und MariaDB
echo "Apache und MariaDB werden gestartet und aktiviert..."
systemctl start apache2
systemctl enable apache2
systemctl start mariadb
systemctl enable mariadb

# MariaDB sichern und root Passwort setzen
echo "MariaDB wird gesichert..."
mysql_secure_installation

# PHPMyAdmin herunterladen und installieren
echo "PHPMyAdmin wird heruntergeladen..."
cd /usr/share
wget https://files.phpmyadmin.net/phpMyAdmin/latest/phpMyAdmin-latest-all-languages.zip
unzip phpMyAdmin-latest-all-languages.zip
mv phpMyAdmin-*-all-languages phpmyadmin
rm phpMyAdmin-latest-all-languages.zip

# PHPMyAdmin Konfiguration einrichten
echo "PHPMyAdmin Konfiguration wird eingerichtet..."
mkdir -p /usr/share/phpmyadmin/tmp
chmod 777 /usr/share/phpmyadmin/tmp
chown -R www-data:www-data /usr/share/phpmyadmin

# Apache Konfiguration für PHPMyAdmin erstellen
echo "Apache Konfiguration wird erstellt..."
cat <<EOF > /etc/apache2/conf-available/phpmyadmin.conf
Alias /phpmyadmin /usr/share/phpmyadmin

<Directory /usr/share/phpmyadmin>
    Options FollowSymLinks
    DirectoryIndex index.php

    <IfModule mod_php7.c>
        <IfModule mod_mime.c>
            AddType application/x-httpd-php .php
        </IfModule>

        <FilesMatch \.php$>
            SetHandler application/x-httpd-php
        </FilesMatch>

        php_value include_path .
    </IfModule>

    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>

<Directory /usr/share/phpmyadmin/setup/lib>
    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>

<Directory /usr/share/phpmyadmin/setup/frames>
    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>

<Directory /usr/share/phpmyadmin/setup/vendors>
    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>

<Directory /usr/share/phpmyadmin/setup/templates>
    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>

<Directory /usr/share/phpmyadmin/libraries>
    <IfModule mod_authz_core.c>
        <RequireAny>
            Require all granted
        </RequireAny>
    </IfModule>
</Directory>
EOF

# Apache Konfiguration aktivieren und Apache neu starten
echo "Apache Konfiguration wird aktiviert und Apache neu gestartet..."
a2enconf phpmyadmin
systemctl reload apache2

# PHPMyAdmin Zugangsdaten anzeigen
echo "Installation abgeschlossen. Sie können PHPMyAdmin unter http://localhost/phpmyadmin aufrufen."
echo "Verwenden Sie die MariaDB Zugangsdaten, um sich anzumelden."
