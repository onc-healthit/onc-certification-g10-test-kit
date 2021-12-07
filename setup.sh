#!/bin/sh
docker-compose pull
docker-compose run inferno bundle exec inferno migrate
