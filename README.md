# Docker Slapd

1. Put SSl certificate files in /home/$USER/slapd/ssl/

    Named as follows: 'ca.crt' 'ldap.crt' 'ldap.key'

2. Edit systemd service and load/start on target server

    ```bash
    vim docker-slapd.service
    sudo systemctl enable $PWD/docker-slapd.service
    sudo systemctl start docker-slapd.service
    ```

3. Create a persistent data container

    ```
    docker create -v /var/lib/ldap -v /etc/ldap/slapd.d/ --name slapd-data hashbang/slapd
    ```

4. Load custom LDIF files remotely with: 

    ```bash
    ldapadd -h ldap.yourdomain.com -p 389 -c -x -D cn=admin,dc=mycorp,dc=com -W -f somefile.ldif
    ```
