#!/bin/bash

# Exit on first error, print all commands.
set -ev
set -o pipefail

# Grab the parent (root) directory.
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
ME=`basename "$0"`

echo ${ME} `date`

source ${DIR}/build.cfg

if [ "${ABORT_BUILD}" = "true" ]; then
  echo "-#- exiting early from ${ME}"
  exit ${ABORT_CODE}
fi


# Start the X virtual frame buffer used by Karma.
if [ -r "/etc/init.d/xvfb" ]; then
    export DISPLAY=:99.0
    sh -e /etc/init.d/xvfb start
fi


# are we building the docs?
if [ "${DOCS}" != "" ]; then

    # Change into the docs directory.
    cd "${DIR}/packages/composer-website"

    # Build the installers.
    ./build-installers.sh

    # Build the documentation.
    npm run doc
    echo ${TRAVIS_BRANCH}
    if [ -n "${TRAVIS_TAG}" ]; then
        export JEKYLL_ENV=production
        if [ "${TRAVIS_BRANCH}" = "master" ]; then
            npm run full:latest
            npm run linkcheck:latest
        elif [ "${TRAVIS_BRANCH}" = "v0.16.x" ]; then
            npm run full:stable
            npm run linkcheck:stable
        fi
    else
       npm run full:unstable
       npm run linkcheck:unstable
    fi

# Are we running functional verification tests?
elif [ "${FVTEST}" != "" ]; then

    # Run the fv tests.
    ${DIR}/packages/composer-tests-functional/scripts/run-fv-tests.sh 
    # append to the previous line to get duration timestamps....  | gnomon --real-time=false 

# Are we running playground e2e tests?
elif [ "${INTEST}" = "e2e" ]; then

    # Run the playground e2e tests.
    cd "${DIR}/packages/composer-playground"
    npm run e2e:main

# Are we running integration tests?
elif [ "${INTEST}" != "" ]; then

    # Run the integration tests.
    ${DIR}/packages/composer-tests-integration/scripts/run-integration-tests.sh 
    # append to the previous line to get duration timestamps....  | gnomon --real-time=false
     
# We must be running unit tests.
else

    # Run the unit tests.
    npm test 2>&1

    # Build the Composer Playground.
    cd "${DIR}/packages/composer-playground"
    npm run build:prod

fi

echo ${ME} `date`
