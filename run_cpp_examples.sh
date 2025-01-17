#!/usr/bin/env bash
# This script runs through the code in each of the cpp examples.
# The purpose is just as an integration test, not to actually train models in any meaningful way.

# Optionally specify a comma separated list of examples to run.
# can be run as:
# ./run_cpp_examples.sh "get_libtorch,run_all,clean"
# To get libtorch, run all examples, and remove temporary/changed data files.

BASE_DIR=`pwd`"/"`dirname $0`
echo "BASE_DIR: $BASE_DIR"
EXAMPLES=`echo $1 | sed -e 's/ //g'`
HOME_DIR=$HOME
ERRORS=""

function error() {
  ERR=$1
  ERRORS="$ERRORS\n$ERR"
  echo $ERR
}

function get_libtorch() {
  echo "Getting libtorch"
  cd $HOME_DIR
  wget https://download.pytorch.org/libtorch/nightly/cpu/libtorch-shared-with-deps-latest.zip
  unzip libtorch-shared-with-deps-latest.zip

  if [ $? -eq 0 ]; then
    echo "Successfully downloaded and extracted libtorch"
    LIBTORCH_PATH="$HOME_DIR/libtorch"   # Store the LibTorch path in a variable.
    echo "LibTorch path: $LIBTORCH_PATH" # Print the LibTorch path
  else
    error "Failed to download or extract LibTorch"
  fi
}

function start() {
  EXAMPLE=${FUNCNAME[1]}
  cd $BASE_DIR/cpp/$EXAMPLE
  echo "Running example: $EXAMPLE"
}

function autograd() {
  start
  mkdir build
  cd build
  cmake -DCMAKE_PREFIX_PATH=$LIBTORCH_PATH ..
  make
  if [ $? -eq 0 ]; then
    echo "Successfully built $EXAMPLE"
    ./$EXAMPLE # Run the executable
  else
    error "Failed to build $EXAMPLE"
    exit 1
  fi
}

function clean() {
  cd $BASE_DIR
  echo "Running clean to remove cruft"
  # Remove the build directories
  find . -type d -name 'build' -exec rm -rf {} +
  # Remove the libtorch directory
  rm -rf $HOME_DIR/libtorch
  echo "Clean completed"
}

function run_all() {
  autograd
}

# by default, run all examples
if [ "" == "$EXAMPLES" ]; then
  run_all
else
  for i in $(echo $EXAMPLES | sed "s/,/ /g")
  do
    echo "Starting $i"
    $i
    echo "Finished $i, status $?"
  done
fi

if [ "" == "$ERRORS" ]; then
  echo "Completed successfully with status $?"
else
  echo "Some examples failed:"
  printf "$ERRORS"
  exit 1
fi
