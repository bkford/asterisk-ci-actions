#!/bin/bash

# Bail on any error
set -e -B

# deploy failsafe
DST_DIR=/home/asterisk-build

declare needs=( end_tag )
declare wants=( dst_dir )
declare tests=( dst_dir )

progdir="$(dirname $(realpath $0) )"
source "${progdir}/common.sh"

declare -A end_tag_array
tag_parser ${END_TAG} end_tag_array || bail "Unable to parse end tag '${END_TAG}'"
${DEBUG} && declare -p end_tag_array

# Set up what to fetch from github
patterns1="{${end_tag_array[artifact_prefix]}-${END_TAG}{.{md5,sha1,sha256,tar.gz,tar.gz.asc},-patch.{md5,sha1,sha256,tar.gz,tar.gz.asc}},{ChangeLog,README}-${END_TAG}.md}"
files=$(eval echo $patterns1)
urls=$(eval echo "https://github.com/asterisk/asterisk/releases/download/${END_TAG}/$patterns1")

cd $DST_DIR
mkdir -p telephony/${end_tag_array[download_dir]}/pending
cd telephony/${end_tag_array[download_dir]}/pending

# Fetch the files and fail if any can't be downloaded.
curl --no-progress-meter --fail-early -f -L --remote-name-all $urls

# If we do get them all, move them into the releases directory.
rsync -vaH --remove-source-files * ../releases/

# Remove any existing RC links
cd ..
rm -f *${END_TAG}-rc*

if [ ${end_tag_array[release_type]} == "rc" ] ; then
	# Create the direct links
	cd releases
	ln -sfr $files ../
	echo 'Release candidate so not disturbing existing links'
	exit 0
fi

# GA release

# Remove previous links
rm -f {asterisk,ChangeLog,README}-${tagarray[certprefix]}${end_tag_array[major]}.*

# Create the direct links
cd releases
ln -sfr $files ../

# Create the -current links
for f in $files ; do
	ln -sfr $f ../${f/${END_TAG}/${end_tag_array[current_linkname]}}
done