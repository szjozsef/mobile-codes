#!/usr/bin/python3

# A script that download the wikipedia pages and other sources
# run download_data.sh which will run this
import os
import sys
import re
import requests
from bs4 import BeautifulSoup

def download_wikipedia():
    subpages = []
    if not os.path.isdir("tmp"):
        os.mkdir("tmp")
    try:
        response = requests.get('https://en.wikipedia.org/wiki/Mobile_country_code', timeout=30)
        response.raise_for_status()
    except HTTPError as http_err:
        print("HTTP error occurred: {}".format(http_err))
        sys.exit(1)
    except Exception as err:
        print("Other error occurred: {}".format(err))
        sys.exit(1)
    else:
        htmlfile = response.text
    soup = BeautifulSoup(htmlfile, 'html.parser')
    for table in soup.find_all('table', class_="wikitable"):
        for links in table.find_all('a', href=True):
            if links.text.startswith('List of mobile network codes in'):
                match = re.search('(.+?)#',links['href'])
                if match:
                    url = match.group(1)
                    if url not in subpages:
                        subpages.append(url)
    subpages.sort()
    wikifiles = len(subpages)
    i = 0
    with open(os.path.join('tmp', 'wiki_' + str(i)),'w') as outfile:
        outfile.write(htmlfile)
    i += 1
    while i <= wikifiles:
        if (i > 0):
            try:
                response = requests.get('https://en.wikipedia.org' + subpages[i - 1], timeout=30)
                response.raise_for_status()
            except HTTPError as http_err:
                print("HTTP error occurred: {}".format(http_err))
                sys.exit(1)
            except Exception as err:
                print("Other error occurred: {}".format(err))
                sys.exit(1)
            else:
                htmlfile = response.text
            with open(os.path.join('tmp', 'wiki_' + str(i)),'w') as outfile:
                outfile.write(htmlfile)
        i += 1

def download_mcc_mnc_table():
    try:
        response = requests.get('https://raw.githubusercontent.com/musalbas/mcc-mnc-table/master/mcc-mnc-table.json', timeout=30)
        response.raise_for_status()
    except HTTPError as http_err:
        print("HTTP error occurred: {}".format(http_err))
        sys.exit(1)
    except Exception as err:
        print("Other error occurred: {}".format(err))
        sys.exit(1)
    else:
        htmlfile = response.text
    with open(os.path.join('tmp', 'mcc-mnc-table.json'),'w') as outfile:
        outfile.write(htmlfile)

if __name__ == '__main__':
    download_wikipedia()
    download_mcc_mnc_table()
