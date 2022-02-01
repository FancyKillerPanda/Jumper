#!/bin/bash

scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
projectRoot=$scriptDir/..

mkdir $projectRoot/bin/ 2>/dev/null
cd $projectRoot/bin/

cp -r $projectRoot/res/ $projectRoot/bin/
odin run $projectRoot/src/ -opt:0 -out:jumper -thread-count:8 -debug -collection:shared=$projectRoot/shared/

cd $projectRoot
