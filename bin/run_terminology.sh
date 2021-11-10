#!/bin/bash
set -e

# Check available memory when running in docker
if [ -f /.dockerenv ]; then
  available_ram_kb=$(cat /proc/meminfo | grep MemTotal | sed -r 's/MemTotal:\s+([0-9]+)\skB/\1/')
  (( available_ram_gb=$available_ram_kb / 1000 / 1000 ))
  if (( $available_ram_gb < 10 )); then
    echo "10 GB of RAM must be available in order to process the terminology, but only $available_ram_gb GB are available"
    exit 1
  fi
fi

./bin/prepare_terminology.sh 2019
bundle exec rake terminology:create_vs_validators["preferred"]
echo "$?"

if [ -n "$CLEANUP" ]
then
  echo 'Deleting 2019 build files'
  bundle exec rake terminology:cleanup_precursors["2019"]
fi

./bin/prepare_terminology.sh 2020
echo "$?"
bundle exec rake terminology:create_vs_validators["preferred","2020","false"]
echo "$?"

if [ -n "$CLEANUP" ]
then
  echo 'Deleting 2020 build files'
  exec bundle exec rake terminology:cleanup_precursors["2020"]
fi

./bin/prepare_terminology.sh 2021
echo "$?"
bundle exec rake terminology:create_vs_validators["preferred","2021","false"]
echo "$?"

if [ -n "$CLEANUP" ]
then
  echo 'Deleting 2021 build files'
  exec bundle exec rake terminology:cleanup_precursors["2021"]
fi
