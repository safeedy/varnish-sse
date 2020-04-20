#!/bin/bash

set -e

echo "Running varnishd with config $VCL_CONFIG"

varnishd -F \
  -f $VCL_CONFIG \
  -s malloc,$CACHE_SIZE \
  $VARNISHD_PARAMS