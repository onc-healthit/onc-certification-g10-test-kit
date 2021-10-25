#!/bin/sh
docker-compose pull
docker-compose run inferno bundle exec rake db:migrate
