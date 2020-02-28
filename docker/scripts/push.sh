#!/bin/bash
set -e

# Push docker tags to a configured docker repo, defaulting to quay.io
# You must run login.sh before running this script.

DEFAULT_DOCKER_REPO="quay.io"
DEFAULT_RELEASE_TARGET="vanilla_llvm+clang+glibc2.27"

# Currently only support pushing to quay.io
DOCKER_REPO=${DEFAULT_DOCKER_REPO}

git_repo=$1    # github.repository format: ORGNAME/REPONAME
git_ref=$2     # github.ref        format: refs/REMOTE/REF
               #                       eg, refs/heads/BRANCH
               #                           refs/tags/v0.9.6-pre
git_sha=$3     # github.sha                GIT_SHA
type_name=$4   # build name, s/+/_/g   eg, vanilla_llvm+clang+glibc2.27
edge=${5:-OFF} # bool                  eg, ON

# edge builds are meant to trace BCC between releases, and provide the newest
# feature sets possible, with the possibility of being less stable.

# refname will be either a branch like "master" or "some-branch",
# or a tag, like "v0.9.6-pre".
# When a tag is pushed, a build is done for both the branch and the tag, as
# separate builds.
# This is a feature specific #to github actions based on the `github.ref` object
refname=$(basename ${git_ref})

# The build type needs to be sanitized into a valid tag, replacing + with _
type_tag="$(echo ${type_name} | sed 's/+/_/g')"

# The main docker image build, copying the bpftrace artifact on top of a vanilla OS image
echo "Building release docker image"
docker build -t ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag} -f docker/Dockerfile.release .

echo "Upload image for git sha ${git_sha} to ${DOCKER_REPO}/${git_repo}"
docker push ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag}

echo "Push tags to branch or git tag HEAD refs"
docker tag ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag} ${DOCKER_REPO}/${git_repo}:${refname}-${type_tag}
docker push ${DOCKER_REPO}/${git_repo}:${refname}-${type_tag}

# Only push to un-suffixed tags for the default release target build type
if [[ "${type_name}" == "${DEFAULT_RELEASE_TARGET}"* ]];then

  # Update branch / git tag ref
  echo "Pushing tags for ${DOCKER_REPO}/${git_repo}:${refname}"
  docker tag ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag} ${DOCKER_REPO}/${git_repo}:${refname}
  docker push ${DOCKER_REPO}/${git_repo}:${refname}

  if [[ "${refname}" == "master" ]];then
    if [[ "${edge}" == "ON" ]];then
      echo "This is an edge build on master, pushing ${DOCKER_REPO}/${git_repo}:edge"
      docker tag ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag} ${DOCKER_REPO}/${git_repo}:edge
      docker push ${DOCKER_REPO}/${git_repo}:edge
    else
      echo "This is a build on master, pushing ${DOCKER_REPO}/${git_repo}:latest :SHA as well"
      docker tag ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag} ${DOCKER_REPO}/${git_repo}:latest
      docker tag ${DOCKER_REPO}/${git_repo}:${git_sha}-${type_tag} ${DOCKER_REPO}/${git_repo}:${git_sha}
      docker push ${DOCKER_REPO}/${git_repo}:latest
      docker push ${DOCKER_REPO}/${git_repo}:${git_sha}
    fi
  fi
fi
