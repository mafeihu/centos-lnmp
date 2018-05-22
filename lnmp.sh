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
mysql_download_path="http://dev.mysql.com/get/Downloads/MySQL-5.6/mysql-5.6.16.tar.gz"
mysql_install_dir="/usr/local/mysql"
php_download_path="http://jp2.php.net/distributions/php-5.5.38.tar.gz"
php_install_path="/usr/local/php"

#设置你要下载的相应的安装包
nginx_name="nginx-1.12.0.tar.gz"
mysql_name="mysql-5.6.16.tar.gz"
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
    #yum install something(更新安装源)
    wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    yum install -y pcre pcre-devel openssl openssl-devel gcc make gcc-c++
    #download nginx
    [ -e $dir ] && cd $dir
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

#install_mysql
install_mysql(){
#install something
  yum install -y bison-devel ncurses-devel automake autoconf bison libtool-ltdl-devel cmake
  #download mysql
  if [ -e $dir ] && cd $dir
  then
    wget $mysql_download_path
    if [ -f $mysql_name ]
    then
      echo -e "\033[42;37m mysql下载成功 \033[0m"
      #tar mysql
      echo -e "\033[42;37m 开始解压mysql源码包 \033[0m"
      tar zxf $mysql_name

      #mkdir dir mysql
      if [ ! -d $mysql_install_dir ]
      then
        mkdir -p $mysql_install_dir
      fi
      echo -e "\033[42;37m 将解压文件转移到mysql安装目录下 \033[0m"
      #move file to mysql_install_dir
      mv mysql-5.6.16/* $mysql_install_dir

      #change dir
      cd $mysql_install_dir
      echo -e "\033[42;37m mysql编译检测........ \033[0m"
      #install
      cmake \
      -DCMAKE_INSTALL_PREFIX=/usr/local/mysql \
      -DMYSQL_DATADIR=/usr/local/mysql/data \
      -DSYSCONFDIR=/etc \
      -DWITH_MYISAM_STORAGE_ENGINE=1 \
      -DWITH_INNOBASE_STORAGE_ENGINE=1 \
      -DWITH_MEMORY_STORAGE_ENGINE=1 \
      -DWITH_READLINE=1 \
      -DMYSQL_UNIX_ADDR=/var/lib/mysql/mysql.sock \
      -DMYSQL_TCP_PORT=3306 \
      -DENABLED_LOCAL_INFILE=1 \
      -DWITH_PARTITION_STORAGE_ENGINE=1 \
      -DEXTRA_CHARSETS=all \
      -DDEFAULT_CHARSET=utf8 \
      -DDEFAULT_COLLATION=utf8_general_ci
      if [ $(echo $?) -eq 0 ]
      then
        echo -e "\033[42;37m mysql编译检测成功，请等待安装。。。。。 \033[0m"
      else
        echo -e "\033[42;37m mysql编译检测失败，重新编译........ \033[0m"
      fi

      make && make install

      # add user mysql
       useradd mysql -s /sbin/nologin -M

      #chown
      chown -R mysql:mysql /usr/local/mysql

      #初始化mysql
      echo -e "\033[42;37m mysql进行mysql初始化........ \033[0m"
      chmod -R 776 /usr/local/mysql/scripts
      scripts/mysql_install_db --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql
      # mv my.cnf
     [ $(echo $?) -eq 0 ] && \cp support-files/my-default.cnf /etc/my.cnf

     chmod +x /etc/init.d/mysqld
     # add to boot auto launch
     chkconfig --add mysqld
     chkconfig mysqld on
     # add to PATH
     PATH=$PATH:/usr/local/mysql/bin/
     echo "export PATH=$PATH:/usr/local/mysql/bin/" >>/etc/profile
     source /etc/profile
    fi
  fi
}
#main function
 main(){
    #create_dir
    #create_dir

    #install nginx
    #start nginx
    read -p " Do you want to install nginx:Y/N " NGINXCONFIRM
    if [ "$NGINXCONFIRM" = "Y" ] || [ "$NGINXCONFIRM" = "y" ];then
            install nginx
            start_nginx
    else
    echo "================== install the next thing============"
    fi

    #install_mysql
    read -p " Do you want to install mysql: Y/N " MYSQLCONFIRM
    if [ "$MYSQLCONFIRM" = "Y" ] || [ "$MYSQLCONFIRM" = "y" ];then
            install_mysql
    else
    echo "=================== install the next thing =============="
    fi
 }
main
