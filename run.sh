#!/bin/bash

main() {
  info 'initialize'
  export FLYWAY_VERSION="4.0.1"
  echo "configuring version $FLYWAY_VERSION of Flyway"

  if [ ! -n "$WERCKER_FLYWAY_MIGRATE_HOST" ]; then
    fail 'missing or empty option host, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_FLYWAY_MIGRATE_USERNAME" ]; then
    fail 'missing or empty option username, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_FLYWAY_MIGRATE_PASSWORD" ]; then
    fail 'missing or empty option password, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_FLYWAY_MIGRATE_DATABASE" ]; then
    fail 'missing or empty option database, please check wercker.yml'
  fi
  
    if [ ! -n "$WERCKER_FLYWAY_MIGRATE_DRIVER" ]; then
    fail 'missing or empty option driver, please check wercker.yml'
  fi

  if [ ! -n "$WERCKER_FLYWAY_MIGRATE_MIGRATION_DIR" ]; then
    fail 'missing or empty option migration-dir, please check wercker.yml'
  fi

  info 'updating apt-get'
  sudo apt-get update

  info 'installing curl'
  sudo apt-get install curl -y

  info 'downloading flyway'
  curl -L https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/4.0.1/flyway-commandline-4.0.1-linux-x64.tar.gz > /tmp/flyway.tar.gz
  mkdir /tmp/flyway
  tar -zxvf /tmp/flyway.tar.gz -C /tmp/flyway
  mkdir "$WERCKER_STEP_ROOT/flyway"
  mv "/tmp/flyway/flyway-$FLYWAY_VERSION/"* "$WERCKER_STEP_ROOT/flyway/"

  info 'starting flyway migration'
  migration_dir="$WERCKER_ROOT/$WERCKER_FLYWAY_MIGRATE_MIGRATION_DIR"
  if cd "$migration_dir";
  then
      debug "changed directory $migration_dir, content is: $(ls -l)"
  else
      fail "unable to change directory to $migration_dir"
  fi

  set +e
  local MIGRATE="$WERCKER_STEP_ROOT/flyway/flyway migrate -url=jdbc:$WERCKER_FLYWAY_MIGRATE_DRIVER://$WERCKER_FLYWAY_MIGRATE_HOST/$WERCKER_FLYWAY_MIGRATE_DATABASE -user=$WERCKER_FLYWAY_MIGRATE_USERNAME -password=$WERCKER_FLYWAY_MIGRATE_PASSWORD -locations=filesystem:$WERCKER_ROOT/$WERCKER_FLYWAY_MIGRATE_MIGRATION_DIR"
  info 'migrating'
  eval "$MIGRATE"

  if [ $? -eq 0 ]
  then
    success 'finished flyway migration';
  else
    fail 'flyway failed';
  fi

  set -e
}

main
