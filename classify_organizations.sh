#!/bin/bash

usage() {
    echo "Usage: $0 [-h] [-o] tweet_dir"
    echo "  -h  Help. Display this message and quit."
    echo "  -o  Output_path/filename. If no path is specified, current directory is default."
    echo "  -t  Directory to use for temporary files"
    echo "  tweet_dir   Directory to tweet JSON files."
    exit
}

if [[ $# == 0 ]]; then
    usage
fi

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
OUTPUT_FNAME=$DIR/output.tsv
WORK_DIR="/tmp"

while [[ $# > 1 ]]
do
  key="$1"
  case $key in
      -h|--help)
      usage
      ;;
      -o|--output)
      OUTPUT_FNAME="$2"
      shift
      ;;
      -t|--tmp-dir)
      WORK_DIR="$2"
      shift
      ;;
  esac
  shift
done

if [ ! -d "${WORK_DIR}" ]; then
    (>&2 echo "Temporary directory does not exist. Exiting...")
fi

if [ ! -w "${WORK_DIR}" ]; then
    (>&2 echo "Temporary directory is not writable. Exiting...")
fi

OUTPUT="${OUTPUT_FNAME}"
if [[ -n $1 ]];
    then
        TWEET_DIR=$1
    else
        usage
fi

FEATURES_UUID=$(cat /dev/urandom | LC_CTYPE=C tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
FEATURES_FPATH="${WORK_DIR}/features_${FEATURES_UUID}.json"

$DIR/op-classifier/src/twitter-feature-extractor/bin/tfx \
  $DIR/op-classifier/src/twitter-feature-extractor/src/tfx/account_types_testing.conf \
  $TWEET_DIR \
  $FEATURES_FPATH

TMPDIR="${WORK_DIR}" $DIR/op-classifier/src/ml-classifier/scripts/classifier \
  --model_file $DIR/resources/model.model \
  -o $OUTPUT \
  $DIR/op-classifier/src/ml-classifier/src/ml2/libsvm_settings.txt \
  $FEATURES_FPATH

rm -f $FEATURES_FPATH
