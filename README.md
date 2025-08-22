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
- [ ] PHP variants (mod, fpm).
- [ ] gitHub Actions to build images based on commits.
- [ ] Dockerfile and docker-compose created from templates.
- [ ] Build and publish images for all versions.
- [ ] Create a DEV image built from git repos.
- [ ] gitHub Actions to autopush to DockerHub.
- [ ] Move from debian to debian-slim.
- [ ] Add and test "OPS" images.
- [ ] Add docker-ojs feature requests (see issues).
- [ ] Extend image with DEV tools.
- [ ] Nginx variant.

# Howto

To RUN images from dockerHub:

```
git clone https://github.com/pkp/containers.git
mv containers journalName && cd journalName
vim .env                         					# Set the IMAGE_SOURCE=docker-io (and modify the rest of variables as you wish)
source .env && wget "https://github.com/pkp/${BUILD_PKP_TOOL}/raw/${PKP_VERSION}/config.TEMPLATE.inc.php" -O ./volumes/config/pkp.config.inc.php
sudo chown 33:33 ./volumes -R && sudo chown 999:999 ./volumes/db -R	# Ensure folders got the propper permissions
docker compose up -d
# Visit your new site and complete the installation as usual (Read about DB access credentials below, in step 5).
```

Detailed instruccions [here](https://github.com/pkp/containers/blob/main/docs/easyOJS.md)

To build your own image:

```
git clone https://github.com/marcbria/docker-pkp.git
docker-compose build --build-arg IMAGE_SOURCE=local --build-arg BUILD_PKP_TOOL=omp --build-arg BUILD_LABEL=$(date "+%Y%m%d-%H%M%S") --no-cache
docker-compose up -d
```

Done.

Visit your new site at https://localhost:8089 and install with parameters found in .env

