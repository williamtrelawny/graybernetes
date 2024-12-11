#!/bin/sh

# create data directory
mkdir -p /data/mongodb

# NOTE: this can't be done as part of the dockerfile because /data will be remapped to a persistent volume