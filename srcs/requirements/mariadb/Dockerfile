# syntax=docker/dockerfile:1
# escape=`
# check=skip=JSONArgsRecommended,error=true

ARG     penultimate_version=debian:bookworm
FROM    ${penultimate_version}
RUN     apt-get update -y
RUN     apt-get install -y mariadb-server

EXPOSE  3306
LABEL   verion="1.0"
LABEL   description="Mariadb server"


COPY tools/init.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


