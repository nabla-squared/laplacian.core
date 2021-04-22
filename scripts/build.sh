#!/usr/bin/env bash

set -e

VERSION='1.0.0'
GROUP='laplacian-core'

PROJECT_BASE_DIR=$(cd $"${BASH_SOURCE%/*}/../" && pwd)
SUBPROJECTS_DIR="$PROJECT_BASE_DIR/subprojects"
DIST_DIR="$PROJECT_BASE_DIR/dist"
LAPLACIAN_HOME="$HOME/.laplacian"
LAPLACIAN_CACHE_DIR="$LAPLACIAN_HOME/cache"
MODEL_SCHEMA_DIR="$PROJECT_BASE_DIR/schema"
MODEL_SCHEMA_FILE="$MODEL_SCHEMA_DIR/model-schema.json"

METAMODEL_MODEL_MODULE_NAME="metamodel-model"
METAMODEL_MODEL_DIR="$SUBPROJECTS_DIR/$METAMODEL_MODEL_MODULE_NAME"
METAMODEL_MODEL_MODULE_PATH="$DIST_DIR/$GROUP.$METAMODEL_MODEL_MODULE_NAME-$VERSION.zip"

DOMAIN_MODEL_PLUGIN_TEMPLATE_MODULE_NAME="domain-model-plugin-template"
DOMAIN_MODEL_PLUGIN_TEMPLATE_DIR="$SUBPROJECTS_DIR/$DOMAIN_MODEL_PLUGIN_TEMPLATE_MODULE_NAME"
DOMAIN_MODEL_PLUGIN_TEMPLATE_MODULE_PATH="$DIST_DIR/$GROUP.$DOMAIN_MODEL_PLUGIN_TEMPLATE_MODULE_NAME-$VERSION.zip"

DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_MODULE_NAME="domain-model-json-schema-template"
DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_DIR="$SUBPROJECTS_DIR/$DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_MODULE_NAME"
DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_MODULE_PATH="$DIST_DIR/$GROUP.$DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_MODULE_NAME-$VERSION.zip"

METAMODEL_PLUGIN_MODULE_NAME="metamodel-plugin"
METAMODEL_PLUGIN_DIR="$SUBPROJECTS_DIR/$METAMODEL_PLUGIN_MODULE_NAME"
METAMODEL_PLUGIN_PATH="$DIST_DIR/$GROUP.$METAMODEL_PLUGIN_MODULE_NAME-$VERSION.jar"
METAMODEL_PLUGIN_BUILT_MODULE="$METAMODEL_PLUGIN_DIR/build/libs/$GROUP.$METAMODEL_PLUGIN_MODULE_NAME-$VERSION.jar"

METAMODEL_PLUGIN_URL="https://github.com/nabla-squared/laplacian.core/releases/download/v1.0.0/laplacian-core.metamodel-plugin-1.0.0.jar"

GRADLE="./gradlew"
ZIP="jar -cfM"

main() {
  # set -x
  generate_json_schema || die
  generate_metamodel_plugin_src || die
  build_metamodel_plugin || die
  update_distribution || die
  update_local_modules || die
}

die() {
  echo "$0 FAILED!!" 1>&2
  exit 1
}

generate_json_schema() {
  rm -rf $JSON_SCHEMA_DIR && \
  laplacian generate \
    --template $DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_DIR \
    --model $METAMODEL_MODEL_DIR \
    --plugin $METAMODEL_PLUGIN_URL \
    --destination $MODEL_SCHEMA_DIR
}

generate_metamodel_plugin_src() {
  rm -rf $METAMODEL_PLUGIN_DIR && \
  laplacian generate \
    --template $DOMAIN_MODEL_PLUGIN_TEMPLATE_DIR \
    --model $METAMODEL_MODEL_DIR \
    --schema $MODEL_SCHEMA_FILE \
    --plugin $METAMODEL_PLUGIN_URL \
    --destination $METAMODEL_PLUGIN_DIR
}

build_metamodel_plugin() {
  (cd $METAMODEL_PLUGIN_DIR
    $GRADLE build
  )
}

update_distribution() {
  rm -rf $DIST_DIR && \
  mkdir -p $DIST_DIR && \
  cp -f $METAMODEL_PLUGIN_BUILT_MODULE $METAMODEL_PLUGIN_PATH && \
  (cd $METAMODEL_MODEL_DIR
    $ZIP $METAMODEL_MODEL_MODULE_PATH . ) && \
  (cd $DOMAIN_MODEL_PLUGIN_TEMPLATE_DIR
    $ZIP $DOMAIN_MODEL_PLUGIN_TEMPLATE_MODULE_PATH . ) && \
  (cd $DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_DIR
    $ZIP $DOMAIN_MODEL_JSON_SCHEMA_TEMPLATE_MODULE_PATH . )

}

update_local_modules() {
  cp -f \
    $METAMODEL_PLUGIN_PATH \
    $METAMODEL_MODEL_MODULE_PATH  \
    $DOMAIN_MODEL_PLUGIN_TEMPLATE_MODULE_PATH \
    $LAPLACIAN_CACHE_DIR
}

main