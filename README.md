# Docker for PKP

A docker image generator for PKP tools (aka. OJS, OMP, OPS).

This project is a refactoring of previous projects, following the work plan outlined in "[pkpContainers: A Proposal for Unification](https://docs.google.com/document/d/1hl3c6PYQgOZWWtwHk2siBTUj3WC6fzrv9hCp7F1jDGQ/edit?usp=sharing)".

You can use this project to RUN and learn about the official images, or to BUILD your own.  
Due to time and resource constraints, we only provide support for issues with the official images.  
Support is not provided for general Docker usage or issues specific to your installation.

Features of the images:
- [x] Able to generate images for different PKP tools.
- [x] Multi-stage approach.
- [x] Debian based.
- [x] Building from tarball.
- [x] Multiple helper scripts.
- [x] Based on [official PHP images](https://hub.docker.com/_/php/).
- [x] PHP extensions installed via [docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer)
- [x] Rootless ready.
- [x] MariaDB/MySQL/PostgreSQL support.
- [x] Monitor security using Docker Scout (or Snyk or Trivy).

# Howto

You can RUN the official images we publish and maintain on DockerHub, or BUILD your own.  
The process is driven by the variables in your .ENV file, so it is important to adjust them according to your needs.  
Your `docker compose up -d` will perform different actions (RUN or BUILD) depending on the value of IMAGE_SOURCE.

### To RUN images from dockerHub:

```
git clone https://github.com/pkp/containers.git journalName
vim .env                         					# Set the IMAGE_SOURCE=docker-io [modify the rest of variables as desired]
source .env && wget "https://github.com/pkp/${PKP_TOOL}/raw/${PKP_VERSION}/config.TEMPLATE.inc.php" -O ./volumes/config/pkp.config.inc.php
sudo chown 33:33 ./volumes -R && sudo chown 999:999 ./volumes/db -R	    # Ensure folders got the proper permissions
docker compose up -d
```

Now, you only need to open your browser to visit your new site and finish the installation with the variables you defined.
Check your .ENV file to know the SERVERNAME, the HTTP_PORT, the DB parameters...

You can find more detailed instructions on how to RUN the official images in [this document](https://github.com/pkp/containers/blob/main/docs/easyOJS.md).

### To BUILD your own image:

```
git clone https://github.com/pkp/containers.git
vim .env                         					# Set the IMAGE_SOURCE=local [modify the rest of variables as desired]
# Run your own image:
docker compose up -d
```

And again, you will need to reach your https://SERVERNAME:$HTTPS_PORT and finish your installation.

Alternatively, instead of editing your .ENV variables, you can override them in the build call as follows:
```
docker compose build --build-arg IMAGE_SOURCE=local --build-arg BUILD_PKP_TOOL=omp --build-arg BUILD_LABEL=$(date "+%Y%m%d-%H%M%S") --no-cache
```

Take in consideration `docker` won't read your .ENV variables, so you should use `docker compose` instead.


# ToDo

List of tasks that need to be done:

- [x] Logs on stderr.
- [ ] OxS installation from commandline.
- [ ] PHP variants (mod and fpm).
- [ ] gitHub Actions to build images based on commits (and autopush to DockerHub).
- [ ] Dockerfile and docker-compose created from templates.
- [ ] Build and publish images for all versions.
- [ ] Create a DEV image built from git repos.
- [ ] Move from debian to debian-slim.
- [ ] Add old "docker-ojs" project feature requests (see issues).
- [ ] Nginx variant.
- [ ] Extend image with DEV tools.
- [ ] Add and test "OPS" images.


# Issues and Disclaimer

If you have questions, improvements or you find any bug, you can report them in this repository's [issue tracker](https://github.com/pkp/containers/issues).

Please note that this project is developed in the spare time of community members, so we cannot provide the level of support we would like, nor a precise roadmap indicating when each feature will be implemented.

PRs are very welcome, but we would appreciate it if we can talk about your proposals in the Issue Tracker or in [Discussions](https://github.com/pkp/containers/discussions) first.
