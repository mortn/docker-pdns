FROM ubuntu:xenial
LABEL maintainer Morten Abildgaard <morten@abildgaard.org>

COPY assets/apt/preferences.d/pdns /etc/apt/preferences.d/pdns
RUN apt-get update && apt-get install -y curl \
	&& curl https://repo.powerdns.com/CBC8B383-pub.asc | sudo apt-key add - \
	&& echo "deb [arch=amd64] http://repo.powerdns.com/ubuntu xenial-auth-master main" > /etc/apt/sources.list.d/pdns.list

RUN apt-get update && apt-get install -y \
	wget \
	git \
	supervisor \
	mysql-client \
	nginx \
	php-cli \
	php-db \
	php-fpm \
	php-mcrypt \	
	pdns-server \
	pdns-backend-mysql \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY assets/nginx/nginx.conf /etc/nginx/nginx.conf
COPY assets/nginx/vhost.conf /etc/nginx/sites-enabled/vhost.conf
COPY assets/nginx/fastcgi_params /etc/nginx/fastcgi_params

COPY assets/php/php.ini /etc/php/7.0/fpm/php.ini
COPY assets/php/php-cli.ini /etc/php/7.0/cli/php.ini

COPY assets/pdns/pdns.conf /etc/powerdns/pdns.conf
COPY assets/pdns/pdns.d/ /etc/powerdns/pdns.d/
COPY assets/mysql/pdns.sql /pdns.sql

### PHP/Nginx ###
RUN rm /etc/nginx/sites-enabled/default
RUN php5enmod mcrypt
RUN mkdir -p /var/www/html/ \
	&& cd /var/www/html \
	&& git clone https://github.com/wociscz/poweradmin.git . \
	&& git checkout 98ecbb5692d4f9bc42110ec478be63eb5651c6de \
	&& rm -R /var/www/html/install

COPY assets/poweradmin/config.inc.php /var/www/html/inc/config.inc.php
COPY assets/mysql/poweradmin.sql /poweradmin.sql
RUN chown -R www-data:www-data /var/www/html/ \
	&& chmod 644 /etc/powerdns/pdns.d/pdns.*

### SUPERVISOR ###
COPY assets/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh

EXPOSE 53 80
EXPOSE 53/udp

CMD ["/bin/bash", "/start.sh"]
