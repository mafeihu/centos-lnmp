#!/bin/bash
#================================================================
#   Copyright (C) 2018  All rights reserved.
#
#   File：：lnmp_install.sh
#   Author：Mafeihu
#   Date：2018/06/18
#   Description：install nginx,mysql,php
#
#================================================================

dir="/data"
#设置nginx,php,nginx下载路径和安装路径
nginx_download_path="http://nginx.org/download/nginx-1.12.0.tar.gz"
nginx_install_dir="/usr/local/nginx"
mysql_download_path=""
mysql_install_dir="/usr/local/mysql"
php_download_path="http://jp2.php.net/distributions/php-5.5.38.tar.gz"
php_install_path="/usr/local/php"

#设置你要下载的相应的安装包
nginx_name="nginx-1.12.0.tar.gz"
mysql_name=""
php_name="php-5.5.38.tar.gz"

#创建文件夹
create_dir(){
   if [ ! -e $dir ]
    then
      mkdir $dir
      echo -e "\033[42;37m 文件创建成功！ \033[0m"
    else
        echo -e "\033[36;41m 你要创建的文件已存在！ \033[0m"
    fi
}

[ -f /etc/init.d/functions ] && . /etc/init.d/functions || exit 1

#install nginx 1.12.0
install_nginx(){
    #yum install something
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    yum install -y pcre pcre-devel openssl openssl-devel gcc make gcc-c++
    #download nginx
    [ -e $dir ] && cd $dir]
    wget $nginx_download_path
    if [ -f $nginx_name ]
    then
      echo -e "\033[42;37m nginx下载成功！ \033[0m"
      tar zxf $nginx_name && cd nginx-1.12.0
      useradd nginx -s /sbin/nologin -M
      echo -e "\033[42;37m 安装nginx！ \033[0m"

      ./configure --prefix=/usr/local/nginx \
       --user=nginx \
       --group=nginx \
       --with-http_stub_status_module \
       --with-http_ssl_module \
       --with-http_gzip_static_module\
       --with-pcre
       echo -e "\033[42;37m nginx检测配置完成，进行安装..... \033[0m"
      [ $(echo $?) -eq 0 ] && make && make install
      [ $(echo $?) -eq 0 ] && echo -e "\033[42;37m nginx安装成功 \033[0m"
    else
      echo -e "\033[36;41m nginx下载失败 \033[0m"
    fi
}

#start nginx
start_nginx(){
   #check syntax
   $nginx_install_dir/sbin/nginx -t
    echo -e "\033[42;37m nginx测试成功 \033[0m"
    if [ $(echo $?) -eq 0 ]
    then
        $nginx_install_dir/sbin/nginx
        if [ $(netstat -lutnp|grep 80 |wc -l) -eq 1 ]
        then
            action "nginx starting success..."  /bin/true
            echo -e "\033[42;37m nginx启动成功了 \033[0m"
        else
            echo -e "\033[36;41m nginx starting fail,plaese check the service！ \033[0m"
        fi
    fi
}






#main function
 main(){
    #create_dir
    create_dir
    #install nginx
    install_nginx
    #start nginx
    start_nginx
 }
main