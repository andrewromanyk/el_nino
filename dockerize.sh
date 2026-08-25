#!/bin/bash

PUSH=false
VERSION="0.0.1"

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --push)
            PUSH=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter passed: $1"
            exit 1
            ;;
    esac
done

docker build -t el_nino:${VERSION} .
docker tag el_nino:${VERSION} andrewromanyk/el_nino:${VERSION}

if [[ "$PUSH" = true ]]; then
    echo "Pushing Docker image to Docker Hub..."
    docker push andrewromanyk/el_nino:${VERSION}
else
    echo "Docker image built but not pushed. Use --push to push the image."
fi