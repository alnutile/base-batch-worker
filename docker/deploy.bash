#!/usr/bin/env bash

# Bail out on first error
set -e

# Get the directory of the build script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Destination to package to $DIR/app/packaged"

# Get the current git commit sha
HASH=$(git rev-parse HEAD)

# Package the app
cd $DIR/../
rsync -ral --progress --ignore-errors --exclude=.idea --exclude=docker --exclude=.git --exclude=.env . $DIR/app/packaged
#git archive --format=tar --worktree-attributes $HASH | tar -xf -  -C $DIR/app/packaged

# Get the stack env
## Will follow up later on this
#aws s3 cp s3://shippingdocker-secrets/env-prod .env
cat $DIR/app/env_prod | sed "s|GITHUB_TOKEN_HERE|${GITHUB_TOKEN}|g" > /tmp/deploy_env
cat /tmp/deploy_env > $DIR/app/packaged/.env
## Or if you do not need to fix the .env
cp $DIR/app/env_prod $DIR/app/packaged/.env

# Production Build Steps
## (Decision between export-ignore'ing docker/develop command or not)
cd $DIR/app/packaged


# Composer install easy now to pass in a github token and what not
composer config -g github-oauth.github.com $GITHUB_TOKEN && composer install --no-dev

# ./develop yarn install
# ./develop gulp --production

## all of this depends on your ECR
## Make sure to set your default profile
## You can use the keys made by CloudFormation for the app
## to push to the ECR
## make sure to follow awscli rules for making profile
## http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html
## and switching as needed export AWS_PROFILE=det

export AWS_PROFILE=securityscanner
eval $(aws ecr get-login --no-include-email --region eu-west-1)
# Build the Docker image with latest code
cd $DIR/app
docker build \
    -t securityscanner .
docker tag securityscanner:latest 364215618558.dkr.ecr.eu-west-1.amazonaws.com/securityscanner:latest
docker tag securityscanner:latest 364215618558.dkr.ecr.eu-west-1.amazonaws.com/securityscanner:$HASH
docker push 364215618558.dkr.ecr.eu-west-1.amazonaws.com/securityscanner:latest
docker push 364215618558.dkr.ecr.eu-west-1.amazonaws.com/securityscanner:$HASH
# Clean up packaged directory
cd $DIR/app/packaged
PWD=$(pwd)
if [ "$PWD" == "$DIR/app/packaged" ]; then
    # The "vendor" directory (any any built assets!) will be owned
    # as user "root" on the Linux file system
    # So we'll use Docker to delete them with a one-off container
    docker run --rm -w /app -v $(pwd):/app ubuntu:16.04 bash -c "rm -rf ./* && rm -rf ./.git* && rm .env*"
    touch .gitkeep
fi