#!/usr/bin/bash

# Nom du script : add_glpi.sh
# Auteur : cherel Johan
# Date de création : 21/01/2024
# Version : 1.0

echo ""
echo ""
echo "Ce script automatisé déploie et configure une installation de GLPI (Gestionnaire Libre de Parc Informatique) sur des machines virtuelles de laboratoire.
Il met à jour la pile LAMP, installe les dépendances nécessaires, configure la base de données MariaDB, télécharge et configure GLPI, 
crée un fichier de configuration Apache vhost, et effectue d'autres tâches liées à la sécurité et à la configuration du serveur web pour le déploiement de GLPI.
"

# Demander confirmation à l'utilisateur
echo ""
read -rp "Voulez-vous exécuter le script avec les valeurs par défaut ? (Oui/Non) : " confirmation
echo ""

# Vérifier la réponse de l'utilisateur
if [[ $confirmation =~ ^[OoYy]$ ]]; then
    echo "Exécution du script avec les valeurs par défaut."
    echo ""
else
    echo "Options du script :"
       echo "-d : Nom de la base de données GLPI (par défaut: glpi)"
       echo "-u : Nom de l'utilisateur de la base de données (par défaut: glpi)"
       echo "-p : Mot de passe de la base de données (par défaut: glpi)"
       echo "-v : Nom du fichier de configuration Apache vhost (par défaut: barzini-glpi.config)"
       echo "-s : Nom du serveur (par défaut: barzini-glpi)"
       echo "-h : Affiche cette aide"
       echo ""
    exit 1
fi

maj="update && apt upgrade "
lamp="apache2 php mariadb-server"
extensions="php-xml php-common php-json php-mysql php-mbstring php-curl php-gd php-intl php-zip php-bz2 php-imap php-apcu php-ldap php8.2-fpm"
dbglpi="glpi"
dbuser="glpi"
dbpassword="glpi"
glpiversion="glpi-10.0.11.tgz"
glpiconfdir="/var/www/glpi/inc/downstream.php"
glpifile="/etc/glpi/local_define.php"
cheminduvhost="/etc/apache2/sites-available"
vhost="barzini-glpi.conf"
servername="barzini-glpi"
ipa=$(hostname -I | cut -d " " -f 1)

# Gestion des options de ligne de commande
while getopts ":d:u:p:v:s:h:" opt; do
  case $opt in
    d) dbglpi="$OPTARG" ;;
    u) dbuser="$OPTARG" ;;
    p) dbpassword="$OPTARG" ;;
    v) vhost="$OPTARG" ;;
    s) servername="$OPTARG" ;;

    h) 
        echo "Options du script :"
        echo "-d : Nom de la base de données GLPI par défaut: glpi"
        echo "-u : Nom de l'utilisateur de la base de données (par défaut: glpi)"
        echo "-p : Mot de passe de la base de données (par défaut: glpi)"
        echo "-v : Nom du fichier de configuration Apache vhost (par défaut: barzini-glpi.config)"
        echo "-s : Nom du serveur (par défaut: barzini-glpi)"
        echo "-h : Affiche cette aide" 
        exit 0
        ;;
    
    \?)
       echo "Option invalide: -$OPTARG" >&2
       exit 1
       ;;
    :)
       echo "Option -$OPTARG nécessite un argument." >&2
       exit 1
       ;;
  esac
done
echo "mise à jour installation de la pile LAMP ainsi que les extensions."
    apt "$maj" -y  > /dev/null 2>&1
    apt install "$lamp" -y > /dev/null 2>&1
    apt install "$extensions" -y > /dev/null 2>&1
    
echo "Création de la base de données MariaDB et atribution des droits, création de l'utilisateur et autorisation accés time zone"
    mysql -u root -e "CREATE DATABASE IF NOT EXISTS $dbglpi; GRANT ALL PRIVILEGES ON $dbuser.* TO $dbuser@localhost IDENTIFIED BY '$dbpassword';"
    mysql -u root -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'localhost';"
    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql
    systemctl restart mariadb.service

echo "Téléchargement de GLPI"
    # shellcheck disable=SC2164
    cd /var/www
    wget "https://github.com/glpi-project/glpi/releases/download/10.0.11/$glpiversion" > /dev/null 2>&1
    
echo "Décompression..."
    tar -xzf $glpiversion -C /var/www/
echo "Atribution à l'utilisateur www-data"
    chown www-data /var/www/glpi/ -R
    
echo "Création du répertoire qui va recevoir les fichiers de configuration de GLPI"
    mkdir -p /etc/glpi 
    chown www-data /etc/glpi/
    
echo "Déplacement du répertoire config"
    mv /var/www/glpi/config /etc/glpi
    
echo "Création du répertoire qui va recevoir les fichiers CSS,Pluggin,etc... de GLPI"    
    mkdir -p /var/lib/glpi
    chown www-data /var/lib/glpi/
    
echo "Déplacement du répertoire Files"
    mv /var/www/glpi/files /var/lib/glpi
    
echo "Création du répertoire log de GLPI"
    mkdir -p /var/log/glpi
    chown -R www-data /var/log/glpi
    chown -R www-data:www-data /var/log/glpi
    
echo "Création du fichier de configuration est déclaration des nouveaux répértoire"
    echo "<?php
            define('GLPI_CONFIG_DIR', '/etc/glpi/');
            if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
                require_once GLPI_CONFIG_DIR . '/local_define.php';
            }" > $glpiconfdir
        chown -R www-data:www-data "$glpiconfdir"
        chmod 644 "$glpiconfdir"

    echo "<?php
        define('GLPI_VAR_DIR', '/var/lib/glpi/files');
        define('GLPI_LOG_DIR', '/var/log/glpi');" > $glpifile
    chown -R www-data:www-data "$glpifile"
    chmod 644 "$glpifile"
    
echo "<VirtualHost *:80>
    ServerName $servername.localhost
    DocumentRoot /var/www/glpi/public
    # Alias /glpi /var/www/glpi/public
    <Directory /var/www/glpi/public>
        Require all granted
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
    <FilesMatch \.php$>
        SetHandler proxy:unix:/run/php/php8.2-fpm.sock|fcgi://localhost/
        </FilesMatch>
    </VirtualHost>" > "$cheminduvhost/$vhost"
    
echo "Désacitver le vhost par default d'apache est active le notre ainsi que le module rewrite,proxy_fcgi setenvif,php8.2-fpm" 
    a2dissite 000-default.conf > /dev/null 2>&1
    a2ensite "$vhost" > /dev/null 2>&1
    a2enmod rewrite > /dev/null 2>&1 
    a2enmod proxy_fcgi setenvif > /dev/null 2>&1
    a2enconf php8.2-fpm > /dev/null 2>&1
    
echo "Configuration PHP-FPM pour Apache2"
    sed -i 's/^session\.cookie_httponly =.*/session.cookie_httponly = on/' /etc/php/8.2/fpm/php.ini
    
echo "Redémarage des services apache et php8.2-fpm"
    systemctl restart apache2 php8.2-fpm.service 

echo "Instalation de glpi........"
    php /var/www/glpi/bin/console db:install -H localhost -d "$dbglpi" -u "$dbuser" -p "$dbpassword" -r -f -q -n 
    php /var/www/glpi/bin/console database:enable_timezones > /dev/null 2>&1
    rm -rf /var/www/glpi/install
    
mysql -e "UPDATE $dbglpi.glpi_users SET is_active = 0 WHERE name = 'tech';"
mysql -e "UPDATE $dbglpi.glpi_users SET is_active = 0 WHERE name = 'normal';"
mysql -e "UPDATE $dbglpi.glpi_users SET is_active = 0 WHERE name = 'post-only';"

echo ""
echo "maintenant connecté vous avec http://$ipa
le login par default et glpi qui est également le mot de passe
!!!! Pour des raison de sécurité changer le mot de passe par dédault de l utilisateur glpi!!!!"

