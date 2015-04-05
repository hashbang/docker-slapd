#!/bin/bash

if [ ! -e /var/lib/ldap/.bootstrapped ]; then

    cat <<EOF

Setting SlapD Config:

ROOTPASS=${ROOTPASS}
DOMAIN=${DOMAIN}
ORG=${ORG}

EOF

ulimit -n 1024

    cat <<EOF | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${ROOTPASS}
slapd slapd/internal/adminpw password ${ROOTPASS}
slapd slapd/password2 password ${ROOTPASS}
slapd slapd/password1 password ${ROOTPASS}
slapd slapd/domain string ${DOMAIN}
slapd shared/organization string ${ORG}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF

    dpkg-reconfigure -f noninteractive slapd

    if [ -e /etc/ldap/ssl/ldap.crt ] && \
       [ -e /etc/ldap/ssl/ldap.key ] && \
       [ -e /etc/ldap/ssl/ca.crt ]; then
    
      echo "SSL Certificates Found"
    
      echo <<EOF >> /etc/ldap/slapd.conf
TLSCACertificateFile    /etc/ldap/ssl/ca.crt
TLSCertificateKeyFile   /etc/ldap/ssl/ldap.key
TLSCertificateFile      /etc/ldap/ssl/ldap.crt
EOF

    fi

    touch /var/lib/ldap/.bootstrapped

fi

/usr/sbin/slapd -h "ldap:/// ldapi:///" -u openldap -g openldap -d 2
