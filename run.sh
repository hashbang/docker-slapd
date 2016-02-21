#!/bin/sh

if [ ! -e /var/lib/ldap/.bootstrapped ]; then

	cat <<- EOF

	Setting SlapD Config:
	
	ROOT_PASS=${ROOT_PASS}
	ADMIN_PASS=${ADMIN_PASS}
	DOMAIN=${DOMAIN}
	ORG=${ORG}

	EOF

	ulimit -n 1024

	cat <<- EOF | debconf-set-selections
	slapd slapd/internal/generated_adminpw password ${ADMIN_PASS}
	slapd slapd/internal/adminpw password ${ADMIN_PASS}
	slapd slapd/password1 password ${ADMIN_PASS}
	slapd slapd/password2 password ${ADMIN_PASS}
	slapd slapd/domain string ${DOMAIN}
	slapd shared/organization string ${ORG}
	slapd slapd/unsafe_selfwrite_acl note
	slapd slapd/invalid_config boolean true
	slapd slapd/no_configuration boolean false
	slapd slapd/purge_database boolean true
	slapd slapd/allow_ldap_v2 boolean false
	slapd slapd/upgrade_slapcat_failure error
	slapd slapd/password_mismatch note
	slapd slapd/backend select HDB
	slapd slapd/dump_database select when needed
	slapd slapd/dump_database_destdir string /var/backups/slapd-VERSION
	slapd slapd/move_old_database boolean true
	EOF

	dpkg-reconfigure -f noninteractive slapd

	if [ -e /etc/ldap/ssl/ldap.crt ] && \
	   [ -e /etc/ldap/ssl/ldap.key ] && \
	   [ -e /etc/ldap/ssl/ca.crt ]; then
	
		echo "SSL Certificates Found"
	
		echo <<- EOF >> /etc/ldap/slapd.conf
		TLSCACertificateFile	/etc/ldap/ssl/ca.crt
		TLSCertificateKeyFile   /etc/ldap/ssl/ldap.key
		TLSCertificateFile	  /etc/ldap/ssl/ldap.crt
		EOF

	fi

	slapd -h "ldapi:///" -u openldap -g openldap

	ldapmodify \
		-Y EXTERNAL \
		-H ldapi:/// \
		<<-EOF
		dn: olcDatabase={0}config,cn=config
		changetype: modify
		add: olcRootPW
		olcRootPW: $(slappasswd -s "${ROOT_PASS}")
		-
		EOF

	killall slapd
	
	sleep 2

	touch /var/lib/ldap/.bootstrapped

fi

/usr/sbin/slapd -h "ldap:/// ldapi:///" -u openldap -g openldap -d 0 &

sleep 5

ldapmodify \
	-Y EXTERNAL \
	-H ldapi:/// \
	<<-EOF
	dn: cn=config
	changetype: modify
	replace: olcSizeLimit
	olcSizeLimit: -1
	-
	EOF

wait
