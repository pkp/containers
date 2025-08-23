# Docker for PKP

A docker image generator for PKP tools (aka. OJS, OMP, OPS).

This is a proof of concept to test ideas to refactor docker-ojs project.

New approach includes:

- [x] Able to generate images for different PKP tools.
- [x] Multi-stage approach.
- [x] Debian based images.
- [x] Building from tarball.

# ToDo
- [x] Rootless ready.
- [x] Monitor security with Docker Scout (or snyk or trivy).
- [x] PostgreSQL support.
- [x] Logs on stderr.
- [ ] OxS installation from commandline.
- [ ] PHP variants (mod and fpm).
- [ ] gitHub Actions to build images based on commits.
- [ ] Dockerfile and docker-compose created from templates.
- [ ] Build and publish images for all versions.
- [ ] Create a DEV image built from git repos.
- [ ] gitHub Actions to autopush to DockerHub.
- [ ] Move from debian to debian-slim.
- [ ] Add docker-ojs feature requests (see issues).
- [ ] Nginx variant.
- [ ] Extend image with DEV tools.
- [ ] Add and test "OPS" images.

# Howto

You can RUN the official images we publish and maintain on DockerHub, or BUILD your own.  
The process is driven by the variables in your .ENV file, so it is important to adjust them according to your needs.  
Your `docker compose up -d` will perform different actions (RUN or BUILD) depending on the value of IMAGE_SOURCE.

### To RUN images from dockerHub:

```
git clone https://github.com/pkp/containers.git journalName
vim .env                         					# Set the IMAGE_SOURCE=docker-io [modify the rest of variables as desired]
source .env && wget "https://github.com/pkp/${BUILD_PKP_TOOL}/raw/${PKP_VERSION}/config.TEMPLATE.inc.php" -O ./volumes/config/pkp.config.inc.php
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

Notice that alternatively, you can override the .ENV variables in the call to `docker compose build`.
docker compose build --build-arg IMAGE_SOURCE=local --build-arg BUILD_PKP_TOOL=omp --build-arg BUILD_LABEL=$(date "+%Y%m%d-%H%M%S") --no-cache

