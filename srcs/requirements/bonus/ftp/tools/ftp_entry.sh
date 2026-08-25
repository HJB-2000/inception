#!/bin/sh
set -e

if [ -z "$FTP_USER" ]; then
    echo "FTP_USER must be set"
    exit 1
fi

if [ ! -f /run/secrets/ftp_password ]; then
    echo "FTP password secret not found"
    exit 1
fi

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

# PAM pam_shells.so requires shell in /etc/shells, else auth fails
grep -qxF /usr/sbin/nologin /etc/shells || echo /usr/sbin/nologin >> /etc/shells

if ! id "$FTP_USER" >/dev/null 2>&1; then
    useradd -d /var/www/html -s /usr/sbin/nologin "$FTP_USER"
fi

echo "$FTP_USER:$FTP_PASSWORD" | chpasswd

chown -R "$FTP_USER:$FTP_USER" /var/www/html

exec /usr/sbin/vsftpd /etc/vsftpd.conf