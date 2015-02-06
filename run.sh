#!/bin/bash

if [ -z "$ROOTPASS" ]; then ROOTPASS=`pwgen -c -n -1 15`; fi
if [ -z "$DOMAIN" ]; then DOMAIN="hashbang.sh"; fi
if [ -z "$ORG" ]; then ORG="Hashbang"; fi

cat <<EOF

SlapD Config:

ROOTPASS=${ROOTPASS}
DOMAIN=${DOMAIN}
ORG=${ORG}

EOF

if [ ! -e /var/lib/ldap/.bootstrapped ]; then

  cat <<EOF | debconf-set-selections
slapd slapd/internal/generated_adminpw password ${ROOTPASS}
slapd slapd/internal/adminpw password ${ROOTPASS}
slapd slapd/password2 password ${ROOTPASS}
slapd slapd/password1 password ${ROOTPASS}
slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
slapd slapd/domain string ${DOMAIN}
slapd shared/organization string ${ORG}
slapd slapd/backend string HDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
slapd slapd/no_configuration boolean false
slapd slapd/dump_database select when needed
EOF

  dpkg-reconfigure -f noninteractive slapd

  slapd -h "ldapi:///" -u openldap -g openldap 
  chown -R openldap:openldap /etc/ldap 

  if [ -e /etc/ldap/ssl/ldap.crt ] && \
     [ -e /etc/ldap/ssl/ldap.key ] && \
     [ -e /etc/ldap/ssl/ca.crt ]; then
  
    echo "SSL Certificates Found"

    chmod 600 /etc/ldap/ssl/ldap.key

    if [ -e /etc/ldap/ssl/dhparam.pem ]; then
      echo "Generating /etc/ldap/ssl/dhparam.pem"
      openssl dhparam -out /etc/ldap/ssl/dhparam.pem 2048
    fi
    
    ldapmodify -Y EXTERNAL -H ldapi:/// -Q <<EOF

dn: cn=config
changetype: modify
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/ldap/ssl/ca.crt
-
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/ldap/ssl/ldap.crt
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/ldap/ssl/ldap.key
-
replace: olcTLSDHParamFile
olcTLSDHParamFile: /etc/ldap/ssl/dhparam.pem
-
replace: olcTLSVerifyClient
olcTLSVerifyClient: never

EOF
  
    killall slapd

  fi

  touch /var/lib/ldap/.bootstrapped

fi

chown -R openldap:openldap /var/lib/ldap

ulimit -n 1024
/usr/sbin/slapd -h "ldap:///" -u openldap -g openldap -d 2
