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
php_download_path="http://jp2.php.net/distributions/php-5.6.30.tar.gz"
php_install_path="/usr/local/php"


http://php.net/get/php-5.6.30.tar.gz/from/this/mirror

#设置你要下载的相应的安装包
nginx_name="nginx-1.12.0.tar.gz"
mysql_name="mysql-5.6.16.tar.gz"
php_name="php-5.6.30.tar.gz"

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

      #配置环境变量
      PATH=$PATH:/usr/local/nginx/bin/
      echo "export PATH=$PATH:/usr/local/nginx/bin/" >>/etc/profile
      source /etc/profile
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

#start_mysql
start_mysql(){
  # start
  /etc/init.d/mysqld start
  if [ $(netstat -lutnp|grep 3306|wc -l) -eq 1 ]
    then
      action "mysql starting success..."  /bin/true
  else
      echo "mysql starting fail,plaese check the service!"
  fi
}

#install_php
install_php(){
    # yum install something
    yum install zlib-devel openssl-devel openssl libxml2-devel libjpeg-devel libjpeg-turbo-devel libiconv-devel freetype-devel libpng-devel gd-devel libcurl-devel libxslt-devel libxslt-devel libmcrypt-devel mcrypt mhash -y
    #download php
    if [ -e $dir ] && cd $dir
        then
        wget $php_download_path
        if [ -f $php_name ]
            then
            echo -e "\033[42;37m php download success \033[0m"
            # tar file
            tar zxf $php_name  && cd php-5.6.30
            echo -e "\033[42;37m Please hold on!The configure output message is so large so that I hide the output message!...\033[0m"
            ./configure --prefix=/usr/local/php \
            --with-config-file-path=/usr/local/php/etc \
            --with-config-file-scan-dir=/usr/local/php/conf.d \
            --with-mysql=/usr/local/mysql \
            --with-mysqli=/usr/local/mysql/bin/mysql_config \
            --with-pdo-mysql=mysqlnd \
            --with-iconv-dir=/usr/local/libiconv \
            --with-freetype-dir=/usr/local/freetype \
            --disable-fileinfo \
            --with-jpeg-dir \
            --with-png-dir \
            --with-zlib \
            --with-libxml-dir=/usr \
            --enable-xml \
            --enable-bcmath \
            --enable-shmop \
            --enable-sysvsem \
            --enable-inline-optimization \
            --with-curl=/usr/local/curl \
            --enable-mbregex \
            --enable-fpm \
            --enable-mbstring \
            --with-mcrypt \
            --enable-ftp \
            --with-gd \
            --enable-gd-native-ttf \
            --with-mhash \
            --enable-pcntl \
            --enable-sockets \
            --with-xmlrpc \
            --enable-zip \
            --enable-soap \
            --with-gettext \
            --enable-opcache=no >> /dev/null 2>&1
            echo -e "\033[42;37m php install .......... \033[0m"
            [ $(echo $?) -eq 0 ] && ln -s /usr/local/mysql/lib/libmysqlclient.so.18 /usr/lib64/ && touch ext/phar/phar.phar
            make >> /dev/null 2>&1
            make install
            echo -e "\033[42;37m php install success\033[0m"

            echo -e "\033[42;37m php will setting.......\033[0m"
            cp php.ini-development /etc/php.ini
            # copy php-fpm
            cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
            cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
            # chmod +x
            chmod +x /etc/init.d/php-fpm
            # add to PATH
            PATH=$PATH:/usr/local/php/bin/
            echo "export PATH=$PATH:/usr/local/php/bin/" >>/etc/profile
            source /etc/profile
            # add to boot auto launch
            chkconfig --add php-fpm
            chkconfig php-fpm  on
        fi
    fi
}

start_phpfpm(){
  # start
  /etc/init.d/php-fpm start
  if [ $(netstat -lutnp|grep 9000|wc -l) -eq 1 ]
    then
      action "php-fpm starting success..." /bin/true
  else
      echo "php-fpm starting fail,plaese check the service!"
  fi

}

#main function
 main(){
    #create_dir
    create_dir
    #install nginx
    read -p " Do you want to install nginx:Y/N " NGINXCONFIRM
    if [ "$NGINXCONFIRM" = "Y" ] || [ "$NGINXCONFIRM" = "y" ];then
            install nginx
    else
    echo "================== install the next thing============"
    fi

    #start nginx
    read -p " Do you want to start nginx:Y/N " NGINXCONFIRM
    if [ "$NGINXCONFIRM" = "Y" ] || [ "$NGINXCONFIRM" = "y" ];then
            start_nginx
    else
    echo "================== run the next thing============"
    fi

    #install_mysql
    read -p " Do you want to install mysql: Y/N " MYSQLCONFIRM
    if [ "$MYSQLCONFIRM" = "Y" ] || [ "$MYSQLCONFIRM" = "y" ];then
            install_mysql
    else
    echo "=================== install the next thing =============="
    fi

    #start_mysql
     read -p " Do you want to start mysql: Y/N " MYSQLCONFIRM
    if [ "$MYSQLCONFIRM" = "Y" ] || [ "$MYSQLCONFIRM" = "y" ];then
            start_mysql
    else
    echo "=================== run the next thing =============="
    fi

    #install_php
    read -p " Do you want to install php: Y/N " MYSQLCONFIRM
    if [ "$MYSQLCONFIRM" = "Y" ] || [ "$MYSQLCONFIRM" = "y" ];then
          install_php
    else
        echo "=================== install the next thing =============="
    fi
    #install-phpfpm
    read -p " Do you want to start php: Y/N " MYSQLCONFIRM
    if [ "$MYSQLCONFIRM" = "Y" ] || [ "$MYSQLCONFIRM" = "y" ];then
          start_phpfpm
    else
        echo "=================== install the next thing =============="
    fi
 }
main
