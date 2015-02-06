# Docker Slapd

1. Put SSl certificate files in /home/$USER/slapd/ssl/

Named as follows: 'ca.crt' 'ldap.crt' 'ldap.key'

2. Edit systemd service and load/start on target server

```bash
vim docker-slapd.conf
sudo systemctl enable $PWD/docker-slapd.conf
sudo systemctl start docker-slapd.service
```

3. Load custom LDIF files remotely with: 

```bash
ldapadd -h ldap.yourdomain.com -p 389 -c -x -D cn=admin,dc=mycorp,dc=com -W -f somefile.ldif
```
