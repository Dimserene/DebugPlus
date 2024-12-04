#!/bin/bash

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

rm DebugPlus.zip 2>/dev/null

sed -i "s/--- VERSION: .*/--- VERSION: $VERSION/" smods.lua
zip -r ./DebugPlus.zip lovely/ assets/ *.lua README.MD *.txt docs/

echo "Zip made for v$VERSION!"