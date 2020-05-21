FROM alpine:3.11
LABEL Maintainer="Thilina, Pituwala <thilina@icehrm.com>" \
      Description="IceHrm Docker Container with Nginx 1.16 & PHP-FPM 7.3 based on Alpine Linux."

# Install packages
RUN apk --no-cache add php7 php7-fpm php7-opcache php7-mysqli php7-json php7-openssl php7-curl \
    php7-zlib php7-xml php7-phar php7-intl php7-dom php7-xmlreader php7-ctype php7-session \
    php7-mbstring php7-gd nginx supervisor curl

# Configure nginx
COPY docker/config/nginx.conf /etc/nginx/nginx.conf
# Remove default server definition
RUN rm /etc/nginx/conf.d/default.conf

# Configure PHP-FPM
COPY docker/config/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY docker/config/php.ini /etc/php7/conf.d/custom.ini

# Configure supervisord
COPY docker/config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup document root
RUN mkdir -p /var/www/html

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody.nobody /var/www/html && \
  chown -R nobody.nobody /run && \
  chown -R nobody.nobody /var/lib/nginx && \
  chown -R nobody.nobody /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
WORKDIR /var/www/html
COPY --chown=nobody ./app /var/www/html/app/
COPY --chown=nobody ./core /var/www/html/core/
COPY --chown=nobody ./web /var/www/html/web/
COPY --chown=nobody ./index.php /var/www/html/index.php
COPY --chown=nobody ./docker/config/config.php /var/www/html/app/config.php

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
