###配置mysql
	
**设置mysql账户密码**
>/usr/local/mysql/bin/mysqladmin -u root password 'new-password'

**MySql实现远程连接，用户grant授权**
>grant all privileges on *.* to root@'%' identified by "your_password" with grant option;

###配置nginx
**添加配置文件**
>cd /usr/local/nginx/conf
>touch servers

**配置nginx.conf**
```
#user  nobody;

worker_processes  4;

error_log  /var/log/nginx/error.log;


#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    include servers/*;
}
```
**配置nginx的服务（servers）；创建一个test.conf并配置**
```
server {
    listen  80;
    server_name localhost;
    charset utf-8;
    location / {
        root /www/;
        index  index.html index.htm index.php;
    }
    
    location @rewrite {
        set $static 0;
        if  ($uri ~ \.(css|js|jpg|jpeg|png|gif|ico|woff|eot|svg|css\.map|min\.map)$) {
            set $static 1;
        }
        if ($static = 0) {
            rewrite ^/(.*)$ /index.php?s=/$1;
        }
    }
    location ~ \.php$ {
        root /www/;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
   
    location ~ /Uploads/.*\.php$ {
        deny all;
    }
}
```
###lnmp服务管理命令
**启动nginx**
>/usr/local/nginx/sbin/nginx

**重启nginx**
>nginx -s reload

**停止nginx**
>nginx -s stop

**启动mysql**
>/bin/systemctl start mysql.service

**重启mysql**
>/bin/systemctl restart mysql.service

**停止mysql**
>service mysql stop

**启动PHP-fpm**
>service php-fpm start

**重启PHP-fpm**
>service php-fpm restart

**停止PHP-fpm**
>service php-fpm stop





