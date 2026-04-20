FROM debian:bookworm

RUN apt-get update && apt-get install -y nginx openssl gettext-base \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/templates/nginx.conf.template
COPY tools/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/run.sh"]