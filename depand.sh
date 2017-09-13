#!/bin/bash

. helper

is_install "jq" && status=0 || status=1
if [ $status -gt 0 ]; then apt install jq -y; fi