# PKP containers

A community-driven collection of container images, build pipelines and configuration examples of PKP applications.

You can use this project to run a production-ready instance of the software or to use it as an example to build your own.

- [Tags](#tags)
- [Images](#images)
- [Usage](#usage)
- [Development](#development)
- [Known issues](#known-issues)
- [Contributing](#contributing)
- [Authors](#authors)
- [License](#license)

## Tags

All current images are relased with at least two tags:

- `pkpofficial/ojs:3_3_0-17-php82-mod-050829.0235`: A unique tag including the tool version, PHP version/handler, and the last 4 digits of the image buildingDate (_explicit_)
- `pkpofficial/ojs:3_3_0-17`: A short alias named as the PKP release tag, always pointing to the latest build of that version (_implicit_)

Additional aliases are also provided:

- `latest` (most recent release),
- `lts` (long-term support version), and
- `stable` (stable branch releases).

This table summarizes all available tags:

Type  | Description  | Example
--- | --- | ---
| **Revision** | explicit: `3_3_0-17-php82-3b94` | For every release, with both an implicit (compact PKP name) and an explicit tag (unique name)
| &nbsp; | implicit: `3_3_0-17` | &nbsp;
| **Stable** | `stable-3_3_0` | Latest release for each maintained stable branch
| **LTS** | `lts-3_3` | Latest long-term support release
| Latest | `latest` | (_development_) Most recent release overall

### Which tag should I use?

The one that fits better with your needs, but if you have doubts, use the last LTS or ask in pkp's forum explaining your specific needs.

You need to keep in mind that only these three aliases and the most recently released image (current) are subject to security checks and maintenance.

- If you want to "pin" an exact build that will never change, use the explicit tag and update manually on each release.
- If you prefer a tag that automatically receives security patches and minor fixes, use the implicit tag.
- If you have more relaxed needs, you may also use `stable` or `lts`.
- The `latest` tag will always be unstable, intended for development, and should never be used in production.

This naming convention is still under discussion and may change based on feedback in the [Discussions](https://github.com/pkp/containers/discussions/16) thread.

## Images

Images in this repository are built on GitHub and published to the GitHub container registry `ghcr.io` and to [the PKP Docker Hub organisation](https://hub.docker.com/u/pkpofficial) `docker.io/pkpofficial`.

- `ojs`, Open Journal System (OJS)
- `omp`, Open Monograph Press (OMP)
- `ops` Open Preprint System (OPS)

The general syntax for referencing an image generated from this repository is as follows:

```
docker.io/pkpofficial/[pkpTool]:[TAG]
  │            │          │       │
  │            │          │       └─ Tag: Specific image (ie: 3_3_0-17-php82-mod-050829.0235)
  │            │          └─ Image: ojs, omp, ops.
  │            └─ Repository: pkpofficial
  └─ Registry host: local, docker.io, ...
```

> **Note:** An example of this is the nomenclature described in this README (with explicit tags and multiple aliases) will apply starting with versions 3.3.0-22, 3.4.0-10, and 3.5.0-2, while the ‘implicit’ nomenclature (equivalent to PKP's, e.g., `ojs:3_2_0-6`) has remained consistent since its inception and will continue to do so in the future.

### ~~Environment variables~~

### Volumes

The container uses at least three writable volumes which are owned by the `www-data` user inside the container.

- `/var/www/files`, a directory
- `/var/www/html/public`, a directory
- `/var/www/html/config.inc.php`, a file that must exist beforehand

## Usage

You can run the official images that are published here or use them as base images to build on top.

### Prerequisites

You can use any OCI-compliant container engine to run these images. The images here are compatible with

- Docker or Podman

and other implementations (e.g. Kubernetes, Incus, Nomad, containerd). Please report back, if you encounter any difficulties. See [Contributing](#contributing) below for details.

For working declaratively with these images locally or remotely, you can use

- Docker Compose

which works both with Docker or Podman both rootless or rootful.

The project in this repository uses Compose files to describe a feature-complete OJS installation together with its dependencies.

To build these images, you will need to run recent enough versions of Docker or Podman in order to build with BuildKit (`buildx`) and newer Containerfile syntax features.

### Environment

Before you can run the containers, you need to create a local copy of the configuration environment:

```sh
cp .env.example .env
```

Modify the values according to your needs.

### Single container by hand

The applications can be run in Docker or Podman. We provide an Omnibus image including a web server, but without a database (See [known issues](#known-issues)). ~~We also provide a PHP FPM image to be used in conjunction with FastCGI-capable web servers.~~

#### Omnibus

Prepare a single empty file as configuration volume for the mutable configuration state, plus a network for name resolution.

```sh
touch config.inc.php
docker network create pkp
```

Only then run the image.

```sh
docker run -d --rm --init \
  --name pkp-ojs \
  --network pkp \
  -p 8080:80 \
  -v ${PWD}/.state/files:/var/www/files:z \
  -v ${PWD}/.state/public:/var/www/html/public:z \
  -v ${PWD}/config.inc.php:/var/www/html/config.inc.php:z \
  ${IMAGE_NAME:-pkpofficial/ojs}:${IMAGE_TAG:-latest}
```

Due to the stateful nature of the application, we need to apply some workarounds. The empty `config.inc.php` volume from before is filled with the expected content. And all volumes are owned by the `www-data` user accessing them.

```sh
docker exec pkp cp config.TEMPLATE.inc.php config.inc.php
docker exec pkp chown www-data:www-data /var/www/{files,html/{public,config.inc.php}}
```

The application needs you to provide valid database credentials. For example, you can run a separate database container.

```sh
docker run -d --rm \
  --network pkp \
  --name ${PKP_DB_HOST:-db} \
  -e MARIADB_DATABASE=${PKP_DB_NAME:-pkp} \
  -e MARIADB_USER=${PKP_DB_USER:-pkp} \
  -e MARIADB_PASSWORD=${PKP_DB_PASSWORD:-insecure} \
  -e MARIADB_RANDOM_ROOT_PASSWORD=1 \
  -v ${PWD}/.state/database:/var/lib/mysql:z \
  mariadb:${MARIADB_TAG:-lts}
```

It will be available on the same internal network that also the application container uses and can be accessed via its DNS name `db`.

You can now access the application at http://localhost:8080 and proceed with the installation.

To ease the handling of containers in regular use and life cycles, we recommend to run [multiple containers with declarative configuration management](#multiple-containers-with-declarative-configuration-management) as exemplified below.

#### ~~PHP FPM with FastCGI-capable reverse proxy~~

### Multiple containers with declarative configuration management

Handling the configuration state in the environment and the mutable state in the volumes is very explicit and requires pointed intervention. We are using Docker Compose to ease this handling with declarative configuration management. This allows us to prescribe desired execution environments.

The process is driven by the variables in the `.env` file, so it is important to adjust them according to your needs.

```sh
cp .env.example .env
sh -c 'source ./.env; wget "https://github.com/pkp/${PKP_TOOL}/raw/${PKP_VERSION}/config.TEMPLATE.inc.php" -O config.inc.php'
docker compose up -d
docker compose exec app chown www-data:www-data /var/www/{files,html/{public,config.inc.php}}
```

Now open your browser at http://localhost:8080 to visit your new site and finish the installation with the values from the `MYSQL_*` variables in your `.env` file.

Please find [the documentation](docs/README.md) for more details on the configuration options exposed via environmental variables or how to maintain the lifecycle of containers running the official images in different scenarios.

### As base image

You can reuse these images in a `FROM` statement as base images, e.g. to install further dependencies for your specific environment.

```Dockerfile
ARG OJS_IMAGE_NAME=pkpofficial/ojs
ARG OJS_IMAGE_TAG=lts-3_5

FROM ${OJS_IMAGE_NAME}:${OJS_IMAGE_TAG}

ADD --link --chown=www-data:www-data https://github.com/pkp/jatsTemplate.git#stable-3_5_0 /var/www/html/plugins/generic/jatsTemplate
ADD --link --chown=www-data:www-data https://github.com/pkp/oaiJats.git#v1_0_6-1 /var/www/html/plugins/oaiMetadataFormats/oaiJats
```

## Development

In the future, we will provide further guidelines for:

- Local development and builds of the base images
- Local development of the integration pipelines and remote build and push of the images
- Contributing to the documentation

## Known issues

This project is happy to receive contributions for increasing its accessibility and applicability.

List of tasks that need to be done to achieve that can be:

- Automating common tasks
  - [ ] simple OxS installation from commandline.
  - [ ] Dockerfile and docker-compose created from templates.
- Automating builds
  - [ ] gitHub Actions to build images based on commits (and autopush to DockerHub).
  - [ ] Build and publish images for all versions.
    - [ ] Add and test "OPS" images.
  - [ ] PHP variants (mod and fpm).
  - [ ] Nginx variant.
- Automating development with Compose for development, `docker develop` or DevContainers
  - [ ] Create a DEV image built from git repos.
  - [ ] Extend image with DEV tools.
- Optimise the images
  - [x] Logs on stderr.
  - [ ] ~~Allow single-container Omnibus installation, based on a not recommended for production-use fat-container with process supervisor for cron and an optional database for evaluation purposes~~
  - [ ] Move from debian to debian-slim.

## Contributing

This project is a continuation from earlier projects in the PKP community, following the work plan outlined in ["pkpContainers: A Proposal for Unification"](https://docs.google.com/document/d/1hl3c6PYQgOZWWtwHk2siBTUj3WC6fzrv9hCp7F1jDGQ/edit?usp=sharing).

| Notice |
|--------|
| This project evolves over time, and criteria may have changed or may change in the future. For example, images were initially built from `git` on Alpine; now we use the released `tarball` on Debian. In any case, changes are always kept to a minimum to help ensure backward compatibility. |

If you have questions, improvements or you find any bug, you can report them in this repository's [issue tracker](https://github.com/pkp/containers/issues).

This project is maintained by community members in their spare time, so support is limited and no detailed roadmap is available. Assistance is only provided for problems with the official images, not for general Docker usage or installation-specific issues.

PRs are very welcome, but we would appreciate it if we can first talk about your proposals in the Issue Tracker or in [Discussions](https://github.com/pkp/containers/discussions).

## Authors

- Anas, @anasfanani
- Jon Richter (TIB Hannover), @tib-rijo
- Marc Bria, @marcbria

## License

This work is licensed under GPL-3.0. See `LICENSE` for terms.

© Public Knowledge Project and contributors, 2025.
