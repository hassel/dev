proxy_set_header  Host                $http_host;
proxy_set_header  X-Real-IP           $remote_addr;
proxy_set_header  X-Forwarded-For     $proxy_add_x_forwarded_for;
proxy_set_header  X-Forwarded-Proto   https;
proxy_http_version 1.1;
proxy_set_header  Connection "";
add_header  Strict-Transport-Security "max-age=31536000; includeSubdomains; preload";
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options "ALLOW-FROM kambi.com";
