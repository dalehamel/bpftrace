#!/bin/bash

DEFAULT_RELEASE_TARGET="vanilla_llvm+clang+glibc2.27"
TYPENAME=$(echo ${NAME} | sed 's/+/_/g')

git_repo=$1 # github.repository format: ORGNAME/REPONAME
git_ref=$2  # github.ref        format: refs/REMOTE/REF
            #                       eg, refs/heads/BRANCH
            #                           refs/tags/v0.9.6-pre
git_sha=$3  # github.sha                GIT_SHA

# refname will be either a branch like "master" or "some-branch",
# or a tag, like "v0.9.6-pre".
# When a tag is pushed, a build is done for both the branch and the tag, as
# separate builds.
# This is a feature specific #to github actions based on the `github.ref` object
refname=$(basename ${git_ref})

if [[ -z "${QUAY_TOKEN}" ]] && echo "QUAY_TOKEN not set" && exit 0

# Forks can push using this approach if they create a quay.io bot user
# with name matching of ORGNAME+bpftrace_buildbot
quay_user="$(dirname ${git_repo})+bpftrace_buildbot":
echo "${QUAY_TOKEN}" | docker login -u="${quay_user}" --password-stdin quay.io

# The main docker image build, copying the bpftrace artifact on top of a vanilla OS image
echo "Building minimal release docker image"
docker build -t quay.io/${git_repo}:${git_sha}-${TYPENAME} -f docker/Dockerfile.minimal .

echo "Upload image for git sha ${git_sha} to quay.io/${git_repo}"
docker push quay.io/${git_repo}:${git_sha}-${TYPENAME}

echo "Push tags to branch or git tag HEAD refs"
docker tag quay.io/${git_repo}:${git_sha}-${TYPENAME} quay.io/${git_repo}:${refname}-${TYPENAME}
docker push quay.io/${git_repo}:${refname}-${TYPENAME}

# Only push to un-suffixed tags for the default release target build type
if [[ "${NAME}" == "${DEFAULT_RELEASE_TARGET}" ]];then

  # Update branch / git tag ref
  echo "Pushing tags for quay.io/${git_repo}:${refname}"
  docker tag quay.io/${git_repo}:${git_sha}-${TYPENAME} quay.io/${git_repo}:${refname}
  docker push quay.io/${git_repo}:${refname}

  if [[ "${refname}" != "master" ]];then
    echo "This is a build on master, pushing quay.io/${git_repo}:latest as well"
    docker tag quay.io/${git_repo}:${git_sha}-${TYPENAME} quay.io/${git_repo}:latest
    docker push quay.io/${git_repo}:latest
  fi
fi
