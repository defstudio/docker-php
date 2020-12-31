#!/usr/bin/env bash

declare -a versions=(
      "7.4"
      "8.0"
)
declare -a targets=(
      "php"
      "tester"
)

for BUILD_TARGET in "${targets[@]}"
  do
    for BUILD_VERSION in "${versions[@]}"
    do
    TARGET_NAME="-$BUILD_TARGET"

    if [ "$BUILD_TARGET" == "php" ]; then
      TARGET_NAME=""
    fi

    docker build --build-arg PHP_VERSION="$BUILD_VERSION" --target="$BUILD_TARGET" --pull -t "$CI_REGISTRY_IMAGE:$BUILD_VERSION$TARGET_NAME" .
    docker push "$CI_REGISTRY_IMAGE:$BUILD_VERSION$TARGET_NAME"

  done

    docker build --build-arg PHP_VERSION="$BUILD_VERSION" --target="$BUILD_TARGET" --pull -t "$CI_REGISTRY_IMAGE:latest$TARGET_NAME" .
    docker push "$CI_REGISTRY_IMAGE:latest$TARGET_NAME"
done

