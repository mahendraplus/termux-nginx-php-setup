#!/bin/bash

# Update and install necessary packages
pkg update -y
pkg upgrade -y
pkg install -y nginx php php-fpm

# Check if Nginx and PHP-FPM were installed correctly
if [ ! -f "$PREFIX/etc/nginx/nginx.conf" ]; then
  echo "Nginx installation failed. Please check the package installation."
  exit 1
fi

if [ ! -f "$PREFIX/etc/php-fpm.d/www.conf" ]; then
  echo "PHP-FPM installation failed. Please check the package installation."
  exit 1
fi

# Configure Nginx
NGINX_CONF="$PREFIX/etc/nginx/nginx.conf"
echo "Configuring Nginx..."

cat > "$NGINX_CONF" << EOL
events {}

http {
    server {
        listen 8080 default_server;
        listen [::]:8080 default_server;
        root $PREFIX/share/nginx/html;
        index index.php index.html index.htm;
        server_name localhost;

        location / {
            try_files \$uri \$uri/ =404;
        }

        location ~ \.php\$ {
            include fastcgi_params;
            fastcgi_pass unix:/data/data/com.termux/files/usr/var/run/php-fpm.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        }

        location ~ /\.ht {
            deny all;
        }
    }
}
EOL

# Configure PHP-FPM
PHP_FPM_CONF="$PREFIX/etc/php-fpm.d/www.conf"
echo "Configuring PHP-FPM..."

sed -i 's|^listen =.*|listen = /data/data/com.termux/files/usr/var/run/php-fpm.sock|' "$PHP_FPM_CONF"

# Create the web root directory if it doesn't exist
WEB_ROOT="$PREFIX/share/nginx/html"
mkdir -p "$WEB_ROOT"

# Create a test PHP file
echo "<?php phpinfo(); ?>" > "$WEB_ROOT/index.php"

# Start services
echo "Starting PHP-FPM and Nginx..."
$PREFIX/bin/php-fpm
$PREFIX/bin/nginx

echo "Setup complete. Open http://localhost:8080 in your browser to see the PHP info page."

# Instructions to restart services
echo "To restart services, use the following commands:"
echo "pkill php-fpm && $PREFIX/bin/php-fpm"
echo "pkill nginx && $PREFIX/bin/nginx"
