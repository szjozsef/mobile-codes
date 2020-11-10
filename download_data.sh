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

# Download the wikipedia page https://en.wikipedia.org/wiki/Mobile_country_code and any related sub-pages
# TODO move this into the python script
cd "${MyDir}"
/usr/bin/wget -q 'https://en.wikipedia.org/wiki/Mobile_country_code' -O "tmp/wiki_0"
additional_ulrs=$(grep 'Mobile_Network_Codes_in_' "tmp/wiki_0" | grep -oP 'href=".*#' | cut -d'"' -f2 | cut -d'"' -f1 | sort -u)
i=0
while read xline; do
    if [ -z "${xline}" ]; then
        continue
    fi
    (( i++ ))
    /usr/bin/wget -q "https://en.wikipedia.org/${xline}" -O "tmp/wiki_${i}"
done <<< ${additional_ulrs}

# Download the data tabe from: musalbas/mcc-mnc-table/master/mcc-mnc-table.json
# TODO move this into the python script
/usr/bin/wget -q 'https://raw.githubusercontent.com/musalbas/mcc-mnc-table/master/mcc-mnc-table.json' -O "tmp/mcc-mnc-table_new.json"
if [ -s "tmp/mcc-mnc-table_new.json" ]; then
    mv -f tmp/mcc-mnc-table_new.json tmp/mcc-mnc-table.json
fi

# call the python parser script with number of wikipedia pages as parameter
/usr/bin/python3 parse.py ${i}

# fix the format of the resulted json files, this should be done in the python script
sed 's/\[/\n    \[/g' tmp/operators.json | sed 's/ $//g' | grep -v ^$ | sed 's/    \[$/\[/g' | sed 's/\]\]/\]\n\]/g' > mobile_codes/json/mnc_operators.json
sed 's/\], \[/\],\n    \[/g' tmp/countries.json | sed 's/ $//g' | grep -v ^$ | sed 's/    \[$/\[/g' | sed 's/\]\]$/\]\n\]/g' | sed 's/\[\[/\[\n    \[/g' > mobile_codes/json/countries.json
if [ -f tmp/mcc-mnc-table.json ]; then
    rm -f tmp/mcc-mnc-table.json
fi
rm -f tmp/wiki_* 2>/dev/null
