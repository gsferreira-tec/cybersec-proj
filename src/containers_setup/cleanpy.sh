#!/usr/bin/bash

echo "Cleaning pycache artifacts..."
sleep 1
echo
echo "Cleaning espoofer/common dir..."
rm -rf ./espoofer/common/__pycache__
sleep 1
echo "Cleaning espoofer/dkim dir..."
rm -rf ./espoofer/dkim/__pycache__
sleep 1
echo "Cleaning espoofer dir..."
rm -rf ./espoofer/__pycache__
sleep 1
echo "Done. Exiting..."
sleep 0.1
