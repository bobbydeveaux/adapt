server {
    listen       80 default_server;
    listen       [::]:80 default_server;
    server_name  _;

    root  /srv/web;
    index index.php index.html index.htm;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~*  \.(jpg|jpeg|png|gif|ico|css|js|woff)$ {
       expires 365d;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_read_timeout 180;
        include fastcgi_params;
    }
}