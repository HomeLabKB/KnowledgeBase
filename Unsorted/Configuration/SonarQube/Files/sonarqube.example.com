server {

    listen 80;
    server_name sonarqube.example.com;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:9000;
    }
}

