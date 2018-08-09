#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings lib test bin
pub run test -p vm
pub run build_runner test