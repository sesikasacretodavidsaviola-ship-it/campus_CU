#!/bin/bash
set -e

counter=0
until mongo -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval "db.adminCommand('ping').ok" --quiet | grep -q 1
do
  sleep 2
  counter=$((counter+1))
  if [ $counter -gt 30 ]; then
    echo "MongoDB startup timed out!"
    exit 1
  fi
done

if ! mongo -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval "rs.status().ok" --quiet | grep -q 1
then
  echo "Initializing replica set..."
  mongo -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
    --authenticationDatabase admin \
    --eval "rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: 'mongo:27017' }] })"
fi

counter=0
until mongo -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --eval "db.hello().isWritablePrimary" --quiet | grep -q true
do
  sleep 2
  counter=$((counter+1))
  if [ $counter -gt 30 ]; then
    echo "Replica set primary election timed out!"
    exit 1
  fi
done

echo "Replica set ready"
