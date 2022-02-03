#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
projectRoot=$scriptDir/..

if [[ "$1" == "--release" ]]; then
	mkdir -p $projectRoot/bin/release/ 2>/dev/null
	cd $projectRoot/bin/release/

	cp -r $projectRoot/res/ $projectRoot/bin/release/
	odin run $projectRoot/src/ -o:size -out:jumper -thread-count:8
else
	mkdir -p $projectRoot/bin/debug/ 2>/dev/null
	cd $projectRoot/bin/debug/

	cp -r $projectRoot/res/ $projectRoot/bin/debug/
	odin run $projectRoot/src/ -opt:0 -out:jumper -thread-count:8 -debug
fi

cd $projectRoot
