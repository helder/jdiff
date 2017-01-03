#!/bin/sh
zip -r release.zip src haxelib.json README.md -x "*/\.*"
haxelib submit release.zip
rm release.zip 2> /dev/null