# PKP applications in containers

This document, created in 2023 during the [Hannover Sprint](https://pkp.sfu.ca/2023/12/29/pkp-sprint-hannover-2023-easy-containers/) by Jarda (Public Knowledge Project), Mathias (University of Bordeaux), Jyrki (TSV) Hanna (University of Göttingen) and [Marc](https://github.com/marcbria/) (Universitat Autònoma de Barcelona) and aims to be a progressive guide to install OJS with docker, going from a clean basic installation to discover the details of the image and the technology like configuration, persistent volumes, version upgrades, and customization of apache2.

## How to use

### TL;DR;

Be sure you properly installed `docker` and `docker-compose` and the `docker` service is running.

```
git clone https://github.com/pkp/containers.git journalName && cd journalName
rm docs templates -Rf                               # Delete folders that are not useful in production
vim .env                         					# Set environment variables as you wish (ojs version, ports, url...)
source .env && wget "https://github.com/pkp/${PKP_TOOL}/raw/${PKP_VERSION}/config.TEMPLATE.inc.php" -O ./volumes/config/pkp.config.inc.php
sudo chown 33:33 ./volumes -R && sudo chown 999:999 ./volumes/db -R	# Ensure folders got the propper permissions
docker compose up -d
# Visit your new site and complete the installation as usual (Read about DB access credentials below, in step 5).

```

### Extended version (under REVIEW)

If you want to run it locally (or in your own server), first you need to install
[docker](https://docs.docker.com/get-docker/) (even [docker-compose](https://docs.docker.com/compose/install/) it's also recommended).

You can have it all up and running in less than 10 minutes following this brief howto:
https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-debian-10

After this, notice that for all available versions, we provide a **docker-compose** configuration file so
you will be able to start a full OJS stack (web app + database containers) in 4 easy steps:

1. Clone this repository in your machine (if you prefer, you can also [download](https://github.com/pkp/containers/archive/master.zip) and unzip it):

    ```bash
    git clone https://github.com/pkp/containers.git
    mv containers journalName && cd journalName
    ```

   Replace "journalName" with a short name of your journal (probably you will like to set the same value you use for COMPOSE_PROJECT_NAME variable).

2. Set your environment variables

    ```bash
    vim .env
    ```

    Edit your .env file to fit your need to fit your needs.
    You will probably like to chage your PKP_VERSION, ports, and names.
    For a detailed description of all the environment variables take a look to ["Environment Variables"](#environment-variables) sectionj.

3. Download the app config file related to your desired tool and version

    ```bash
    source .env && wget "https://github.com/pkp/${PKP_TOOL}/raw/${PKP_VERSION}/config.TEMPLATE.inc.php" -O ./volumes/config/pkp.config.inc.php
    ```

    If your are running docker on windows (with Powershell), specify manually the tool and the version you like to download as in:

    ```bash
    wget "https://github.com/pkp/ojs/raw/3_3_0-21/config.TEMPLATE.inc.php" -O ./volumes/config/pkp.config.inc.php
    ```

4. Make sure your volumes have the right permissions

    ```bash
    sudo chown 33:33 ./volumes -R && sudo chown 999:999 ./volumes/db -R	# Ensure folders got the propper permissions
    ```

5. Run the stack:
    ```bash
    docker compose up -d
    ```

    Docker-compose will pull images from DockerHub and do all the hard work for you to rise a full functional OJS stack.
    If all goes as expected you will see your app_container informing apache is RUNNING successfully.

    ```
    INFO success: apache entered RUNNING state, process has stayed up for > than 1 seconds (startsecs)
    ```

    You can add the "-d" parameter to the call if you like to run it detached.

4. Access **http://127.0.0.1:8081** and continue through web installation process.

    Note that the database connection needs the following options:

    - **Database driver**: `mysqli` (or "mysql" if your php is lower than 7.3)
    - **Host**: `db` (which is the name of the db service in the docker-container.yml)
    - **Username**: `pkp`
    - **Password**: `changeMePlease` (change with the password you set in your environment variables)
    - **Database name**: `pkp`
    - _Uncheck_ "Create new database"
    - _Uncheck_ "Beacon"

    And the  "Directory for uploads:" acording to your compose.yml "/var/www/files"

| **TIP:**             |
|:---------------------|
| To go through the OJS installation process automatically, set the environment variable `PKP_CLI_INSTALL=1`, and use the other .env variables to automatize the process. |
| **WARNMING:** This feature was not tested yet with the new images. Report if you got any issue. |

That's all. Easy peasy, isn't it?

Ok, let's talk about more complex concepts and scenarios.

<!--
## Building local images

The official image will work for 90% of the people but, if you don't want external dependencies or you like to modify our official Dockerfiles to fit your specific needs you will need to build your images in your machine.

Each version folder also includes an alternative yml file called `docker-compose-local.yml`.

This compose won't ask dockerHub for the required images, it will build a docker image locally.

To do this...

1. Go to your preferred version folder and and build the image as follows:
    ```bash
    $ docker build -t local/ojs:3_2_1-4 .
    ```

    If something goes wrong, double-check if you ran the former command with the right version number or in a folder without the local Dockerfile.

2. Once the image is built, you can run the stack locally telling compose to use the local yaml file with the `-f`/`--file` option as follows:
    ```bash
    $ docker compose --file docker-compose-local.yml up
    ```
-->

## Versions

Before start, you would probably like to read about the Tag Naming Contentions](https://github.com/pkp/containers/tree/main?tab=readme-ov-file#tag-naming-conventions) used in this project.

In the official images, the different TOOL versions could be running over different PHP versions (5 to 8...) acording to PKP's recommendations.
In future we are planning to add variants with different web servers ([Apache HTTP Server](https://httpd.apache.org/), [nginx](https://nginx.org/)) and tools.

_Currently, not all these combinations work! We are mostly focused in Apache2. PR are welcome_

All version tags can be found at [Docker Hub Tags tab](https://hub.docker.com/r/pkpofficial/ojs/tags/).

(If no webserver is mentioned in the tag, then Apache is used).

**WARNING:** Unsupported versions are still provided on Docker Hub to facilitate updating legacy projects, but under no circumstances should they be used in production, as they contain outdated and insecure code.

## Environment Variables

The image understand the following environment variables:

| NAME                   | Default           | Info                                                                             |
|:----------------------:|:-----------------:|:---------------------------------------------------------------------------------|
| SERVERNAME             | "$PROJECT_DOMAIN" | Used to generate httpd.conf and certificate.                                     |
| PKP_TOOL               | ojs               | PKP tool to be used (ojs, omp, ops). Only OJS & OMP images avaliable right now   |
| PKP_VERSION            | lts               | OJS version to be deployed                                                       |
| COMPOSER_PROJECT_NAME  | demo              |                                                                                  |
| PKP_CLI_INSTALL        | 0                 | Used to install ojs automatically when container starts                          |
| DB_HOST                | db                | Database host                                                                    |
| DB_USER                | pkp               | Database user                                                                    |
| DB_PASSWORD            | changeMePlease    | Database password                                                                |
| DB_NAME                | pkp               | Database name                                                                    |
| HTTP_PORT              | 8080              | Http port                                                                        |
| HTTPS_PORT             | 8443              | Https port                                                                       |


_**Note:** PKP_CLI_INSTALL and certificate features are under construction._

## Special Volumes

Docker content is ephemeral by design, but in some situations you may want
to keep some data **persistent** between Docker restarts (e.g., database content,
uploaded files, plugin development, etc.).

In this project we include a structure of directories inside the ./volumes folder
but they are empty and disabled by default.
To enable them, **you only need to uncomment the volume lines in your
compose.yml** and populate the folders accordingly.

When you run `docker compose`, it will mount the volumes with persistent
data and allow you to share files from your host with the container.

These are the usual volumes you will probably want to map:


| Host                                    | Container  | Volume                                | Description                    |
|:----------------------------------------|:----------:|:--------------------------------------|:-------------------------------|
| ./volumes/public                        | app        | /var/www/html/public                  | All public files               |
| ./volumes/private                       | app        | /var/www/files                        | All private files (uploads)    |
| ./volumes/config/db.charset.conf        | db         | /etc/mysql/conf.d/charset.cnf         | mariaDB config file            |
| ./volumes/config/pkp.config.inc.php     | app        | /var/www/html/config.inc.php          | OJS config file                |
| ./volumes/config/php.custom.ini         | app        | /usr/local/etc/php/conf.d/custom.ini  | PHP custom.init                |
| ./volumes/config/apache.htaccess        | app        | /var/www/html/.htaccess               | Apache2 htaccess               |
| ./volumes/logs/app                      | app        | /var/log/apache2                      | Apache2 Logs                   |
| ./volumes/logs/db                       | db         | /var/log/mysql                        | mariaDB Logs                   |
| ./volumes/db                            | db         | /var/lib/mysql                        | mariaDB database content       |
| ./volumes/db-import                     | db         | /docker-entrypoint-initdb.d           | DB init folder (with SQLs)     |
| ./volumes/plugins                       | app        | /var/www/html/plugins                 | Ensure host plugins are sync with the ojs version |
| /etc/localtime                          | app        | /etc/localtime                        | Sync clock with the host one.  |
| TBD                                     | app        | /etc/ssl/apache2/server.pem           | SSL **crt** certificate        |
| TBD                                     | app        | /etc/ssl/apache2/server.key           | SSL **key** certificate        |

In this image, we use "bind volumes" with relative paths because it gives you a clear view of where your data is stored.

The downside of these volumes is that they cannot be "named," and Docker will
store them using an absolute path (which makes portability more difficult),
but I prefer having better control over where data is stored rather than leaving it to Docker.

Remember that this is just an image, so feel free to modify it to fit your needs.

You can add your own volumes. For instance, it makes sense for a plugin developer
or a themer to create a volume for their work, keeping a persistent copy on
the host for the new plugin or theme (see plugins mapping in the previous table).

An alternative approach for developers is to work with their own local
Dockerfile, which will be built to pull the plugin from their repository...
but this will be significantly slower than using volumes.

Last but not least, these storage folders need to exist with the correct permissions
before you run your `docker compose` command, or it will fail.

To ensure your volumes have the correct permissions, you can run the following commands:

   ```bash
   $ sudo chown 33:33 ./volumes -R
   $ sudo chown 999:999 ./volumes/db -R
   ```

So, permissions for volumes folders are like... "all the content will be owned by apache2
user and group ("www-data" or uid 33 and gid 33 inside the container), execpt for db
and logs/db folders (if exist) that will be owned by mysql user and group (uid and gid 999)".

| **TIP:**             |
|:---------------------|
| The MySQL/MariaDB images include a REALLY nice entrypoint that will run scripts and SQL dumps *if your DB hasn't been created yet*. This feature is great for site migrations, testing, demos, development dummy data, etc. |
| To use it, you just need to drop your mysqldump file in the `volumes/db-import` folder (create it if it doesn't exist), map this folder as a volume in your compose.yml, and start your container to enjoy the magic. |

## Built in scripts

The Dockerfile includes some scritps at "/usr/local/bin" to facilitate common opperations:

| Script               | Container  | Description                                                                                                           |
|:---------------------|:----------:|:----------------------------------------------------------------------------------------------------------------------|
| pkp-run-scheduled    | ojs        | Runs "php tools/runScheduledTasks.php". Called by cron every hour.                                                    |
| pkp-cli-install      | ojs        | Uses curl to call the ojs install using pre-defined variables (experimental).                                         |
| pkp-pre-start        | ojs        | Enforces some config variables and generates a self-signed cert based on ServerName.                                  |
| pkp-upgrade          | ojs        | Runs "php tools/upgrade.php upgrade". (experimental: know issue when config.inc.php is a volume)                      |
| pkp-variable         | ojs        | Replaces the variable value in config.inc.php (ie: pkp-variable variable newValue)                                    |
| pkp-migrate          | ojs        | Takes a dump.sql, public and private files from "migration" folder and builds and builds a docker site (experimental) |

Some of those scripts are still experimental, so please, be careful when you use them.

You can call the scripts outside the container as follows:

   ```bash
   $ docker exec -it ojs_app_journalname /usr/local/bin/pkp-variable session_check_ip Off
   ```

## Upgrading OJS

Thanks to docker, the ugrade process is easy and straightforward.

0. We assume that the source version (e.g. "pkpofficial/ojs:2_4_8-5") is running on Docker. If that’s not the case, check how to "dockerize" it.

1. **Set the new version** in your `.env`file (or in your compose.yml if you don't use vars).

     Replace the old version: ```2_4_5-2```

     with the new one:        ```3_2_1-4```

2. **Pull and restart the container**. Since you changed the version, Docker Compose will pull the updated OJS image from Docker Hub. When you run `docker compose up -d`, it will automatically stop the existing container and recreate it using the new image (remember that containers are not persistent), bringing everything up again.
   ```bash
   docker compose pull
   docker compose up -d
   ```

3. **Run the upgrade script** to update the OJS database and files. The easiest way is to use the helper script inside your OJS container with [`docker exec`](https://docs.docker.com/engine/reference/commandline/exec/) and run the built-in `pkp-upgrade` in a single line:

    $ docker exec -it ojs_app_journalname /usr/local/bin/pkp-upgrade

| **TIP:** How to find your container name                                                                                                  |
|:------------------------------------------------------------------------------------------------------------------------------------------|
| You can see the names of all your containers with `docker ps -a`. The ones related to OJS will look something like `ojs_app_journalname`. |
| Use `grep` to filter them, for example: `$ docker ps -a | grep ojs_app`                                                                   |


Before the upgrade you will like to [diff](https://linux.die.net/man/1/diff) your `config.inc.php` with the version of the new OJS version to learn about new configuration variables. Be specially carefully with the charsets.

| **WARNING:** May I upgrade directly to the last OJS stable version?                                                        |
|:---------------------------------------------------------------------------------------------------------------------------|
| It depends on your initial version. The recommended upgrade route is:<br/> **2.x > 2.4.8-5 > 3.1.2-4 > 3.2.1-4 > 3.3.x-x** |


## Apache2

As mentioned, right now the only available stack is Apache2, so configuration files and
volumes are designed assuming you will work with Apache.

If you want Apache to work differently, you can either build your own image locally or
continue using the official images and map your config files in your `compose.yml`.

So, if you want to change something (for example, your PHP settings), you only need to
create a `./volumes/config/php.custom.ini` outside the container and uncomment the
corresponding volume in your `compose.yml`.

Check the volumes section for a list of folders and files that we think could be useful
to overwrite or extend to fit your needs.

### Restful URLs (aka. clean URLs)

~~By default the restful_url are enabled and Apache is already configured,
so there is no need to use index.php over url.~~

Although it can be tempting to change things sometimes, to avoid confusions, this project
keeps the default PKP settings, so the `restful_url` variable is inactive by default,
just like in OJS/OMP/OPS.

### SSL

By default at the start of Apache one script will check if the SSL certificate
is valid and its CN matches your SERVERNAME, if don't it will generate a new one.
The certificate can be overwritten using a volume mount (see `compose.yml` file).

_**Note:** This feature is under reveiw and could change in future._

### SSL handled by an external service

If you have an external service in front handling SSL connections (often referred as
*SSL offloading* or *SSL termination*) you need to add a new line containing
`PassENV HTTPS` in `pkp.conf`, inside the main `<VirtualHost *:80>` section.


## Troubleshooting

#### **I have trouble with Mac**
In general with docker, there are some known issues with the new Mac’s ARM architecture : https://stackoverflow.com/questions/73294020/docker-couldnt-create-the-mpm-accept-mutex . Alternative solution (other than hardcoding mutex settings) might be to build docker image also for arm64 platform (https://github.com/bitnami/containers/issues/4679). Some work was started in this line in gitLab building pipelines with promising preliminary results.

#### **I have trouble with Windows**
Instructions to run are for GNU/Linux (as fas as Linux is the natural platform for docker and servers) but is also possible to run it in windows. The wget instructions use variables defined in the env-file but this is not compatible with windows powershell, so would be nice to find an alternative that works all platforms. As a temporary solution we add clear instructions for windows users, that need to modify the inliner to get the right version of the config.TEMPLATE file.

#### **May I get an image based on nginx?**
A nice addition for docker images would be offer nginx image to replace the existing apache2.

#### **How could I deal with plugins?**
One thing you always will need to deal with is plugins. This is now possible but could be improved with a few ideas that appear during the sprint as:
- Use volumes managed with git
- Create new pkp-plugins script helper that backups and download the essential release plugins for your version. 

#### **Is there any roadmap?**
The project is build based on the needs of the participants. If you like to join, contact marc.bria@uab.cat.
There is no formal roadmap, but we like to implement all the suggestion we made in the [Containers for PKP](https://docs.google.com/document/d/1AoGn1K4ep4vf7ylIS7wU2ybCLHdJNpkDRND7OhfRG-I/edit#heading=h.tpkz1jmp2yzm) document.
Priorities right now are (by order):
1. Create new images based on "[Containers for PKP](https://docs.google.com/document/d/1AoGn1K4ep4vf7ylIS7wU2ybCLHdJNpkDRND7OhfRG-I/edit#heading=h.tpkz1jmp2yzm)" proposal.
2. Automatize docker images building and pushing to different repositories.
3. Fixing Mac image issues.

#### **When I try to install I got an error...**
> Errors occurred during installation A database error has occurred: SQLSTATE[HY000] [2002] No such file or directory (SQL: create table announcement_types (type_id bigint not null auto_increment primary key, assoc_type smallint not null, assoc_id bigint not null) default character set utf8 collate 'utf8_general_ci')

When you run the compose.yml, you will be creating different containers with different names.
In this project, the database container will be named as "db" so you can refer it in the "app" container to reach the DB.
So, nevermind if you use the web installer, or you set it manually in the config.inc.php, or you ask the Dockerimage to do it in your behalf... in all cases, you need to be sure you to set "db" when you are asked about the hostname of the database.

## License

GPL3 © [PKP](https://github.com/pkp)
