FROM debian:bookworm

RUN apt-get update && apt-get install -y mariadb-server \
    && rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/init.sh /usr/local/bin/run.sh

RUN chmod +x /usr/local/bin/run.sh
EXPOSE 3306

CMD ["/usr/local/bin/run.sh"]