#!/bin/bash
# this is a copy of the file in MetadataGeonetwork
# testing whether this works fine here too, for now

# get user input
usage="$(basename "$0") [-h] [-b bump]
--------------------------------------------------
Bump the version and create the necessary commits.
This can be run from a SNAPSHOT version. In that case, it will remove the SNAPSHOT and produce a 'finalisation' branch.
Afterwards, it bumps the version and produces a 'starting' branch for the new SNAPSHOT version.

where:
    -h  show this help text
    -b  the desired bump (major, minor, patch)"
while getopts ':hb:' option; do
  case "$option" in
    h) echo "$usage"
       exit
       ;;
    b) bump=$OPTARG
       ;;
    :) printf "missing argument for -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
   \?) printf "illegal option: -%s\n" "$OPTARG" >&2
       echo "$usage" >&2
       exit 1
       ;;
  esac
done
shift $((OPTIND - 1))

# where the pomfile lives
pomfile=../pom.xml
changelogfile=../CHANGELOG.md
# what remote we push to
remote=origin
today=$(date +%F)

# check bump validity
valid_bumps=("major" "minor" "patch")
if { [[ ! "major" = ${bump} ]] && [[ ! "minor" = ${bump} ]] && [[ ! "patch" = ${bump} ]]; }; then
  echo "bump type should be either one of: ${valid_bumps[*]}"
  exit 1
fi
echo "Bump type: $bump"

# current branch
current_branch=$(git rev-parse --abbrev-ref HEAD)

# current version
current_version=$(mvn -f $pomfile help:evaluate -Dexpression=project.version -q -DforceStdout)
echo "Current version: $current_version"

# first step: finalise if we are on a snapshot
branch1=""
if [[ $current_version == *-SNAPSHOT ]]; then
  echo "We are on a snapshot."
  mvn -f $pomfile validate -Dremove-snapshot -DgenerateBackupPoms=false -q
  new_version=$(mvn -f $pomfile help:evaluate -Dexpression=project.version -q -DforceStdout)

  # replace the snapshot reference in changelog.md so we can't forget
  escaped_version=$(echo "$current_version" | sed -E 's/([][\.])/\\\1/g')
  echo "Escaped version: $escaped_version"
  echo "New version: $new_version"
  regex_from="s/## \[$escaped_version\].*/## [$new_version] - $today/"
  echo "Regex source: $regex_from"
  sed -E "$regex_from" -i $changelogfile
  git_tag="vl-$new_version"
  echo "Git tag: $git_tag"

  # switch to the 'finalise' branch and commit the pom with the new version set
  branch="feature/finalise-$new_version"
  echo "Created local branch $branch"
  git checkout -b "$branch"
  git add $pomfile
  git add $changelogfile
  git commit -m "Finalising $new_version"
  git tag "$git_tag"
  git push --set-upstream $remote "$branch"
  git push $remote "$git_tag"

  # prepare for cleanup
  branch1="$branch"
fi

# second step: bump the version as desired
current_version=$(mvn -f $pomfile help:evaluate -Dexpression=project.version -q -DforceStdout)
mvn -f $pomfile validate -D "bump-$bump" -q
mvn -f $pomfile validate -D "add-snapshot" -q
new_version=$(mvn -f $pomfile help:evaluate -Dexpression=project.version -q -DforceStdout)
escaped_version=$(echo "$current_version" | sed -E 's/([][\.])/\\\1/g')
branch="feature/started-$new_version"
regex_from="s/(## \[$escaped_version\].*)/## [$new_version]\n\n\1/"
sed -E "$regex_from" -i ../CHANGELOG.md
echo "Created local branch $branch"
git checkout -b "$branch"
git add $pomfile
git add ../CHANGELOG.md
git commit -m "Starting $new_version [skipci]"
git push --set-upstream $remote "$branch"
git checkout "$current_branch"
git branch -D "$branch"

# if the SNAPSHOT finalise branch was used... delete it
if  [[ -n "$branch1" ]]; then
  git branch -D "$branch1"
fi
