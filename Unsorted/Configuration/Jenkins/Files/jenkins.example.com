server {

    listen 80;
    server_name jenkins.example.com;

    location / {
        include proxy_params;
        proxy_pass http://127.0.0.1:8080;
    }
}

