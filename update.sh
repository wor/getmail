#!/usr/bin/env bash
# Quick script to automate repo updating from upstream tarball releases.
# Exits with '2' if now new versions found.

get_version_changelog() {
    local changelog="${1}"
    local version="${2}"
    awk -v version="${version}" '
    BEGIN { out_fn="none" }
    /^Version / { out_fn="/dev/null"; }
    $0 ~ "^Version " version { out_fn="/dev/stdout"; }
    { print > out_fn; }
    '   "${changelog}"
}

get_new_versions() {
    local changelog="${1}"
    local last_version="${2}"
    awk -v version="${last_version}" '
    BEGIN { out_fn="none" }
    /^Version / { out_fn="/dev/stdout"; }
    $0 ~ "^Version " version { out_fn="/dev/null"; exit; }
    /^Version / { print $2 > out_fn; }
    ' ${changelog}
}

if [[ "${1}" ]]; then
    new_versions=("${1}")
else
    upstream_changelog="http://pyropus.ca/software/getmail/CHANGELOG"
    echo "Error: No version given as first parameter, for example, 4.35.0" 1>&2
    echo "Do you want to determine needed update versions automatically?"
    echo "  Versions are parsed from the upstream changelog: ${upstream_changelog}"
    echo "(CTRL-C to cancel)"
    read

    last_repo_ver=$(git log --grep=Version --pretty=oneline upstream | cut -d' ' -f3 | head -1)

    echo "last 'upstream' branch version found: $last_repo_ver"

    declare -a new_versions
    mapfile -t new_versions < \
        <(curl -s ${upstream_changelog} | get_new_versions - "${last_repo_ver}")

    if [[ "${#new_versions[@]}" == 0 ]]; then
        echo "No new versions found."
        exit 2
    fi

    echo "Found new versions:"
    for v in "${new_versions[@]}"; do
        echo $v
    done
fi

set -o errexit
repo="$(pwd)"
branch="upstream"

for version in "${new_versions[@]}"; do
    echo "Updating version: ${version}"
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

    get_version_changelog "docs/CHANGELOG" "${version}" \
        | git commit -F - --author="${author}"

    git push origin "${branch}":"${branch}"
    rm -rf "/tmp/getmail-${version}"
done
