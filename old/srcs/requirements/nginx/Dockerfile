# syntax=docker/dockerfile:1
# escape=`
# check=skip=JSONArgsRecommended,error=true
FROM    debian:bookworm
ARG     TARGET_APP1=nginx
ARG     TARGET_APP2=openssl
ARG     TARGET_APP3=curl
RUN     apt-get update
RUN     apt-get upgrade -y
RUN     echo "TARGET_APP=${TARGET_APP}" `
&& apt-cache policy ${TARGET_APP}
RUN     echo ${TARGET_APP}
RUN     apt update `
&& apt install -y ${TARGET_APP1} `
${TARGET_APP2} ${TARGET_APP3}
COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/init.sh /entrypoint.sh
RUN     chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


