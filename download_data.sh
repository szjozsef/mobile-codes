#!/bin/bash

pushd $(dirname $0) > /dev/null
MyDir=$(pwd -P)
popd > /dev/null

cd "${MyDir}"

if [ ! -d tmp ]; then
    mkdir tmp
fi

if [ ! -d iso3166 ]; then
    mkdir iso3166
fi

# Download from github the deactivated/python-iso3166 library
# TODO if possible install it as a python package, on my system this was not possible
cd iso3166
# TODO curl 7.68.0 has native etag support with : --etag-compare etag.txt --etag-save etag.txt
header=""
if [ -f etag.txt ]; then
    oetag=$(< etag.txt)
    header="If-None-Match: $oetag"
fi
if [ ! -z "${header}" ]; then
    wget -S --header="${header}" 'https://raw.githubusercontent.com/deactivated/python-iso3166/master/iso3166/__init__.py' -O __init__.py.tmp --output-file out.txt
else
    wget -S 'https://raw.githubusercontent.com/deactivated/python-iso3166/master/iso3166/__init__.py' -O __init__.py.tmp --output-file out.txt
fi
xCode=$?
if [ ${xCode} -eq 0 -o ${xCode} -eq 8 ]; then
    etag=$(grep -oP 'ETag: .*' out.txt | tail -1 | cut -d ' ' -f2)
    if [[ ! "${oetag}" == "${etag}" ]]; then
        echo "${etag}" > etag.txt
    fi
    statCode=$(grep -oP "HTTP/.*" out.txt | tail -1 | cut -d' ' -f2)
    if [[ "${statCode}" == "200" ]]; then
        mv -f __init__.py.tmp __init__.py
    else
        rm -f __init__.py.tmp
    fi
fi
rm -f out.txt
cd "${MyDir}"

# call the python parser script
/usr/bin/python3 parse.py

# fix the format of the resulted json files, this should be done in the python script
sed 's/\[/\n    \[/g' tmp/operators.json | sed 's/ $//g' | grep -v ^$ | sed 's/    \[$/\[/g' | sed 's/\]\]/\]\n\]/g' > mobile_codes/json/mnc_operators.json
sed 's/\], \[/\],\n    \[/g' tmp/countries.json | sed 's/ $//g' | grep -v ^$ | sed 's/    \[$/\[/g' | sed 's/\]\]$/\]\n\]/g' | sed 's/\[\[/\[\n    \[/g' > mobile_codes/json/countries.json
