# docker-things

A package manager to easily install any docker-things app

--------------------------------------------------------------------------------

### Dependencies

 - **docker** - All the apps are built in docker containers
 - **git**    - All the apps are fetched from the github docker-things organization

--------------------------------------------------------------------------------

### Usage

```
Usage: /usr/bin/docker-things [OPTION] [THING]

OPTIONS:
  backup       - Backup app
  build        - Build app
  connect      - Connect to the docker image
  delete       - Delete app
  fifo-listen  - Listens to FIFO messages from apps
  get          - Get repository
  install      - Install app launcher (get & build app if needed)
  kill         - Kill app
  list         - List available things
  logs         - Show app logs
  restart      - Restart app
  restore      - Restore backup of the app
  self-upgrade - Upgrade docker-things from the github repo
  set-default  - Set app as default for the host system
  start        - Start app
  status       - Show app status
  stop         - Stop app
  update       - Update repository
  upgrade      - Upgrade app
```

--------------------------------------------------------------------------------

### Installing docker-things

This one-liner will fetch this repo, will install the docker-things script and then will remove the downloaded repo.

```sh
git clone https://github.com/docker-things/docker-things.git /tmp/docker-things && bash /tmp/docker-things/docker-things.sh self-install && rm -rf /tmp/docker-things
```

--------------------------------------------------------------------------------

### Installing apps

This command will install `firefox`, `chromium` and `dropbox`

```sh
docker-things install firefox chromium dropbox
```

--------------------------------------------------------------------------------

### Upgrading apps

This command will upgrade `firefox`, `chromium` and `dropbox`

```sh
docker-things upgrade firefox chromium dropbox
```

--------------------------------------------------------------------------------

### Uninstalling apps

This command will uninstall `firefox`, `chromium` and `dropbox`

```sh
docker-things delete firefox chromium dropbox
```

--------------------------------------------------------------------------------

### Set apps as default for the host system apps

Assuming you installed Firefox and want it to be your default browser, run this:

```sh
docker-things set-default firefox
```

--------------------------------------------------------------------------------

### Integration

##### xdg-open

The apps are able to open stuff between each other by using the host xdg-open binary through FIFO.

So, if you click a link in Mattermost it will be able to open Firefox or whichever is your default browser.

##### notify-send

Notifications sent through notify-send will also be shown seamlessly by using FIFO pipes.
