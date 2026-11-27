#!/usr/bin/env bash

# Regenerates dependabot.yml from templates for all maintained release branches.

set -eo pipefail
script_dir="$(dirname "$(readlink -f "$0")")"
# shellcheck source=./common.sh
source "${script_dir}/common.sh"

require_vars MAINTAINED_RELEASE_BRANCHES_COUNT
require_tools gh envsubst

dependabot_file="${script_dir}/../../.github/dependabot.yml"
main_tmpl="${script_dir}/dependabot-main.yml.tmpl"
release_tmpl="${script_dir}/dependabot-release-branch.yml.tmpl"
github_actions_tmpl="${script_dir}/dependabot-github-actions.yml.tmpl"

branches=$("${script_dir}/find-maintained-release-branches.sh")
echo "Maintained release branches:"
echo "${branches}"

{
  printf 'version: 2\nupdates:\n'
  cat "${main_tmpl}"
  for branch in ${branches}; do
    echo "Adding dependabot entries for ${branch}" >&2
    BRANCH="${branch}" envsubst '$BRANCH' < "${release_tmpl}"
  done
  cat "${github_actions_tmpl}"
} > "${dependabot_file}"

echo "Updated ${dependabot_file}"
