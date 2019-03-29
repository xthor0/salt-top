server {
	listen 3200 default_server;
	listen [::]:3200 default_server;

    error_page 404 /custom_404.html;
    location = /custom_404.html {
        root /usr/share/nginx/html;
        internal;
    }

    location ~ ^/.+$ {
        rewrite ^ /custom_404.html break;
    }

}

server {
	listen 3200;
	listen [::]:3200;

	server_name www.example.com;

    location / {
       proxy_pass http://localhost:3400/;
    }
}
