#!/usr/bin/env bash

set -o errexit

git checkout master
./update.sh

echo "Rebase passwordeval to upstream, press enter to continue.."
read

git checkout passwordeval
git rebase upstream

echo "Rebase master to passwordeval, press enter to continue.."
read

git checkout master
git rebase passwordeval

echo "Force push all to upstream (github), press enter to continue.."
read

git push --force --all
