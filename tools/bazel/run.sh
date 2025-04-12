#!/usr/bin/env sh
# Load environment variables from .env
set -a
[ -z "${BUILD_WORKSPACE_DIRECTORY-}" ] || ! [ -f "$BUILD_WORKSPACE_DIRECTORY/.env" ] || . "$BUILD_WORKSPACE_DIRECTORY/.env"
set +a
# Use the expected working directory
[ -z "${BUILD_WORKING_DIRECTORY-}" ] || cd "$BUILD_WORKING_DIRECTORY"
exec "$@"
