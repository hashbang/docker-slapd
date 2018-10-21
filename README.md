# Docker Slapd

## Deployment

1. Create persistent data volumes:

    ```
    docker volume create slapd-config
    docker volume create slapd-data
    docker volume create slapd-ssl
    ```

2. Ensure desired DNS is pointed to target instance

3. Get letsencrypt certs into slapd-ssl volume:

    ```
    docker run \
      --cap-add=NET_ADMIN \
      --name=letsencrypt \
      -v slapd-ssl:/config \
      -e EMAIL=staff@hashbang.sh \
      -e URL=ldap.hashbang.sh \
      -e VALIDATION=http \
      -p 80:80 \
      -e TZ=UTC \
      linuxserver/letsencrypt
    ```

    Be sure the files are named: ldap.crt, ldap.key and ca.cert

    They may need to be renamed manually depending on live config expectations.

4. Install/start systemd unit

    Use the unit file from the root of this repo:

    ```bash\
    vim $PWD/docker-slapd.service
    sudo systemctl enable $PWD/docker-slapd.service
    sudo systemctl start docker-slapd.service
    ```

## Configuration

Configuration is all managed within the ldap database itself so you will need
to run LDIF files or ```ldapmodify``` alter live configuation of ldap rather
than traditional configuration management.

### Example to load arbitrary ldif file

```bash
ldapadd -h ldap.yourdomain.com -p 389 -c -x -D cn=admin,dc=mycorp,dc=com -W -f somefile.ldif
```

### Look at raw state of ldap configuration on disk

```
docker exec -it slapd cat /etc/ldap/slapd.d/cn\=config.ldif
```

## Backups

### Backup all volumes

```bash
sudo tar \
  -cvpzf ldap-backup.tar.gz \
  --exclude=/backup.tar.gz \
  --one-file-system /var/lib/docker/volumes/
```

### Restore all volumes

```bash
sudo tar  \
  -xvpzf /path/to/backup.tar.gz \
  -C /var/lib/docker/volumes \
  --numeric-owner
```
