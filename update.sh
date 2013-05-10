#!/bin/bash
# Quick script to automate repo updating from upstream tarball releases.

set -o errexit

[[ "${1}" ]] || { echo "Error: First parameter should be version number like 4.35.0"; exit 1; }

repo="$(pwd)"
branch="upstream"
version="${1}"

author="charlesc <charlesc-getmail-support@pyropus.ca>"
url="http://pyropus.ca/software/getmail/old-versions/"
package="getmail-${version}.tar.gz"

cd /tmp
git clone -b "${branch}" "${repo}" "getmail-${version}"
cd "getmail-${version}"

wget "${url}${package}"
tar -xavf "${package}" --overwrite --strip-components 1
rm "${package}"
git add .

awk "BEGIN { out_fn=\"none\" }/^Version / { out_fn=\"/dev/null\"; } /^Version ${version}/ { out_fn=\"/dev/stdout\"; } { print > out_fn; }" docs/CHANGELOG \
    | git commit -F - --author="${author}"

git push origin "${branch}":"${branch}"
