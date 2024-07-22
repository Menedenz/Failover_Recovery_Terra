#!/bin/bash

# Update package lists
sudo apt-get update -y

# Install Apache and OpenSSL
sudo apt-get install -y apache2 openssl

# Enable SSL module and headers
sudo a2enmod ssl
sudo a2enmod headers

# Create a directory for the SSL certificate
sudo mkdir -p /etc/apache2/ssl

# Create the certificate files directly
cat <<EOL > /etc/apache2/ssl/self_signed_certificate.pem
${cert_content}
EOL

cat <<EOL > /etc/apache2/ssl/private_key.pem
${key_content}
EOL

# Create a simple HTML file with the required text and background
cat <<EOL > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Passive EC2</title>
    <style>
        body {
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            background: linear-gradient(to bottom right, #FFA500, #FF4500);
            color: white;
            font-family: Arial, sans-serif;
            font-size: 3em;
        }
    </style>
</head>
<body>
    Passive EC2
</body>
</html>
EOL

# Create an Apache configuration file for the default SSL site
sudo bash -c 'cat <<EOL > /etc/apache2/sites-available/default-ssl.conf
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        SSLEngine on
        SSLCertificateFile /etc/apache2/ssl/self_signed_certificate.pem
        SSLCertificateKeyFile /etc/apache2/ssl/private_key.pem

        <FilesMatch "\\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>

        <Directory /var/www/html>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    </VirtualHost>
</IfModule>
EOL'

# Enable the SSL site
sudo a2ensite default-ssl.conf

# Restart Apache to ensure all changes take effect
sudo systemctl restart apache2
