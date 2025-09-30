#!/bin/bash

# Normalize PHP_BASE_IMAGE to generate a tag-friendly string
normalizeWebServer() {
    local webServer=$1
    # Replace 'apache' with 'mod' and remove colons
    phpTag="${webServer//apache/mod}"
    phpTag="${phpTag//:/}"
}

# Extract version numbers for alias tags
extractVersions() {
    VER_3DIGITS="${PKP_VERSION%%-*}"                        # Remove from '-' to the end
    VER_2DIGITS=$(echo "$PKP_VERSION" | cut -d'_' -f1-2)    # Take first two digits
}

# Show build parameters and ask for confirmation
showBuildParameters() {
    echo "A BUILD will be performed and DockerHub tags will be published for:"
    echo "  - PKP_TOOL: ${PKP_TOOL}"
    echo "  - PKP_VERSION: ${PKP_VERSION}"
    echo "  - PHP_BASE_IMAGE: ${PHP_BASE_IMAGE}"
    echo "Tags and Alias:"
    echo "  - Explicit (unique name): ${REMOTE_REPO}:${TAG_EXPLICIT}"
    echo "You will also have the option to create or update the following aliases:"
    echo "  - Implicit (pkp name): ${REMOTE_REPO}:${TAG_IMPLICIT}"
    echo "  - LTS: lts-${VER_2DIGITS}, lts"
    echo "  - Stable: stable-${VER_3DIGITS}"
    echo "  - Latest: latest"
    read -p "Are you sure you want to continue? (Y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
}

# Ask if alias should be created and pushed
pushAlias() {
    local aliasName=$1
    read -p "Do you want to create alias '${aliasName}'? (y/n): " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        docker tag "${TAG_FINAL}" "${REMOTE_REPO}:${aliasName}"
        docker push "${REMOTE_REPO}:${aliasName}"
        echo "Alias '${aliasName}' pushed."
    fi
}

# Main script
main() {

    # Load .env and expand any variable references
    if [ -f .env ]; then
        source .env
    else
        echo ".env not found"
        exit 1
    fi

    # Override with arguments if provided
    if [ -n "$1" ]; then
        PKP_TOOL="$1"
    fi
    if [ -n "$2" ]; then
        PKP_VERSION="$2"
    fi

    if [ "$IMAGE_SOURCE" != "local" ]; then
        echo "IMAGE_SOURCE is not 'local', skipping local build."
        exit 1
    fi

    REMOTE_REPO="pkpofficial/${PKP_TOOL}"

    normalizeWebServer "$PHP_BASE_IMAGE"

    # Generate implicit and explicit laceholders
    TIMESTAMP=$(date +%y%m%d.%H%M)
    TAG_EXPLICIT="${PKP_VERSION}-${phpTag}-${TIMESTAMP}"
    TAG_IMPLICIT="${PKP_VERSION}"

    extractVersions

    showBuildParameters

    # To pass arguments to docker compose:
    export PKP_VERSION
    export PKP_TOOL

    # Build image with docker compose
    echo "Building image with docker compose..."
    docker compose build app

    LOCAL_IMAGE="local/${PKP_TOOL}:${PKP_VERSION}"
    TAG_FINAL="${REMOTE_REPO}:${TAG_EXPLICIT}"

    # Tag image and push to Remote Registry (DockerHub)
    echo "Tagging image for DockerHub..."
    docker tag "${LOCAL_IMAGE}" "${TAG_FINAL}"
    echo "Pushing explicit tag: ${TAG_EXPLICIT}"
    docker push "${TAG_FINAL}"

    # Ask separately for each additional alias
    echo "Generating alias..."
    pushAlias "${TAG_IMPLICIT}"
    pushAlias "latest"
    pushAlias "stable-${VER_3DIGITS}"
    pushAlias "lts-${VER_2DIGITS}"
    pushAlias "lts"

    echo "All done."
}

main "$@"
