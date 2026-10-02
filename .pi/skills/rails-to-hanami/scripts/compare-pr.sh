#!/usr/bin/env bash
#
# compare-pr.sh — fetch a merge diff from the reference repos to see how a
# specific Rails→Hanami piece was actually converted.
#
# Usage:
#   compare-pr.sh <pr_number>            # from the Hanami repo (default)
#   compare-pr.sh <pr_number> rails      # from the Rails repo
#
# Set REPO_HANAMI / REPO_RAILS to override the origins.
set -euo pipefail

PR="${1:?usage: compare-pr.sh <pr_number> [rails]}"
SIDEB="${2:-hanami}"

REPO_HANAMI="${REPO_HANAMI:-pulibrary/orcid_princeton_hanami}"
REPO_RAILS="${REPO_RAILS:-pulibrary/orcid_princeton}"

case "${SIDEB}" in
  hanami) REPO="${REPO_HANAMI}" ;;
  rails)  REPO="${REPO_RAILS}"  ;;
  *) echo "unknown side: ${SIDEB} (use 'hanami' or 'rails')" >&2; exit 2 ;;
esac

echo "==> ${REPO} PR #${PR}"
# GitHub exposes a per-PR unified diff at the pull/NN.diff endpoint.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
   gh pr view "${PR}" --repo "${REPO}" \
     --json title,mergeCommit,files,url &&
   gh pr diff "${PR}" --repo "${REPO}"
else
   # Fall back to the public .diff endpoint (no auth).
   url="https://github.com/${REPO}/pull/${PR}.diff"
   echo "fallback: ${url}"
   if command -v curl >/dev/null 2>&1; then
      curl -fsSL "${url}" || {
        echo "curl failed (PR may be unmerged or private)" >&2; exit 1; }
   else
      echo "install curl or gh to fetch the diff" >&2; exit 1
   fi
fi
