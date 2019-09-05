# docker-things

A package manager to easily install any docker-things app

--------------------------------------------------------------------------------

### Dependencies

 - docker
 - git
 - bash

--------------------------------------------------------------------------------

### Usage

```
Usage: ./docker-things.sh [OPTION] [THING]

OPTIONS:
  list         - List available things
  build        - Build docker image
  install      - Install app launcher (get & build if needed)
  start        - Start docker image
  stop         - Stop docker image
  kill         - Kill docker image
  get          - Get repository
  update       - Update repository
  delete       - Delete app
  self-install - Install this script in /usr/bin/docker-things
```

--------------------------------------------------------------------------------

### Installing docker-things

This one-liner will fetch this repo, will install the docker-things script and then will remove the downloaded repo

```sh
git clone https://github.com/docker-things/docker-things.git /tmp/docker-things && bash /tmp/docker-things/docker-things.sh self-install && rm -rf /tmp/docker-things
```

--------------------------------------------------------------------------------

### Installing apps

This command will install `firefox`, `chromium` and `dropbox`

```sh
docker-things install firefox chromium dropbox
```
