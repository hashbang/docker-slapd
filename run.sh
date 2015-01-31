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
  touch /var/lib/ldap/.bootstrapped


fi
exec /usr/sbin/slapd -h "ldap:///" -u openldap -g openldap -d 2
