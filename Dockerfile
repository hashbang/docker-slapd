FROM debian:jessie

RUN apt-get update && \
    LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y \
      ldap-utils \
      slapd \
      pwgen && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD slapd.conf /tmp/slapd.conf

ADD run.sh /tmp/run.sh

EXPOSE 389

# Default command to run on boot

CMD ["bash","/tmp/run.sh"]
