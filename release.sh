#!/bin/sh
rm -rf release
mkdir -p release
cp -R -u maux haxelib.json release
chmod -R 777 release
cd release
zip -r release.zip ./ && mv release.zip ../
cd ..