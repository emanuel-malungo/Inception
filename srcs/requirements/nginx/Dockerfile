FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx openssl \
    && rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/sites-available/default
COPY tools/run.sh /usr/local/bin/run.sh
RUN chmod +x /usr/local/bin/run.sh

RUN mkdir -p /etc/nginx/ssl

EXPOSE 80 443

CMD ["/usr/local/bin/run.sh"]