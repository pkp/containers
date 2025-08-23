# Docker for PKP

A docker image generator for PKP tools (aka. OJS, OMP, OPS).

This project is a refactoring of previous projects, following the work plan outlined in "[pkpContainers: A Proposal for Unification](https://docs.google.com/document/d/1hl3c6PYQgOZWWtwHk2siBTUj3WC6fzrv9hCp7F1jDGQ/edit?usp=sharing)".

You can use this project to RUN and learn about the official images, or to BUILD your own.  

Features of the images:
- [x] Able to generate images for different PKP tools.
- [x] Multi-stage approach.
- [x] Debian based.
- [x] Building from tarball.
- [x] Updated list of php modules and OS libraries.
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


# Tag Naming Conventions  

The general syntax for referencing a PKP image is as follows:
```
docker.io/pkpofficial/[pkpTool]:[TAG]
  │            │          │       │
  │            │          │       └─ Tag: Specific image.
  │            │          └─ Image: ojs, omp, ops.
  │            └─ Repository: pkpofficial
  └─ Registry host: local, docker.io, ...
```

All current images are relased with at least two tags:  
- **Explicit**: A unique tag including the tool version, PHP version/handler, and the last 4 digits of the image digest (e.g., `pkpofficial/ojs:3_3_0-17-php82-3b94`).
- **Implicit**: A short alias named as the PKP release tag (e.g., `pkpofficial/ojs:3_3_0-17`), **always pointing to the latest build of that version**.  

Additional aliases are also provided: `latest` (most recent release), `lts` (long-term support version), and `stable` (stable branch releases). 

This table summarizes all available tags:
| Type        | Description                                                                                   | Example                                        |
| ----------- | --------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| **Current** | For every release, with both an implicit (compact PKP name) and an explicit tag (unique name) | explicit: `3_3_0-17-php82-3b94`<br/> implicit: `3_3_0-17` |
| **Stable**  | Latest release for each maintained stable branch                                              | `stable-3_3_0`                                 |
| **LTS**     | Latest long-term support release                                                              | `lts-3_3`                                      |
| **Latest**  | Most recent release overall (for development only)                                            | `latest`                                       |

## Which image should I use? 

The one that fits better with your needs, but if you have doubts, use the last LTS (or ask in pkp's forum explaining your specific needs).

You need to keep in mind that only these three aliases and the most recently released image (current) are subject to security checks and maintenance, so...
- If you want to "pin" an exact build that will never change, use the explicit tag and update manually on each release.
- If you prefer a tag that automatically receives security patches and minor fixes, use the implicit tag. 
- If you have more relaxed needs, you may also use `stable` or `lts`. 
- The `latest` tag will always be unstable, intended for development, and should never be used in production.  

This naming convention is still under discussion and may change based on feedback in the [Discussions](https://github.com/pkp/containers/discussions/16) thread.  


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

This project is maintained by community members in their spare time, so support is limited and no detailed roadmap is available. Assistance is only provided for problems with the official images, not for general Docker usage or installation-specific issues.

PRs are very welcome, but we would appreciate it if we can first talk about your proposals in the Issue Tracker or in [Discussions](https://github.com/pkp/containers/discussions).
