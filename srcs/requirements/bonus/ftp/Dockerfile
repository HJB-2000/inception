FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        vsftpd \
        tini && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/vsftpd/empty

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/ftp_entry.sh /ftp_entry.sh

RUN chmod +x /ftp_entry.sh

ENTRYPOINT ["/usr/bin/tini", "--", "/ftp_entry.sh"]