#!/bin/bash
set -e

docker buildx build --platform linux/amd64 -t onc-certification-g10-test-kit-terminology_builder:latest -f Dockerfile.terminology --no-cache --load .
docker compose -f terminology_compose.yml up
