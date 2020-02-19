#!/bin/bash

# For now only quay.io is supported, but this could be portable to dockerhub
# and other image repositories.

# Forks can push using this approach if they create a quay.io bot user
# with name matching of ORGNAME+bpftrace_buildbot, or by setting QUAY_BOT_NAME


# Set this value as QUAY_TOKEN in the github repository settings "Secrets" tab
[[ -z "${QUAY_TOKEN}" ]] && echo "QUAY_TOKEN not set" && exit 0

# Set this to match the name of the bot user on quay.io
[[ -z "${QUAY_BOT_NAME}" ]] && QUAY_BOT_NAME="bpftrace_buildbot"

quay_user="$(dirname ${git_repo})+${QUAY_BOT_NAME}":
echo "${QUAY_TOKEN}" | docker login -u="${quay_user}" --password-stdin quay.io
