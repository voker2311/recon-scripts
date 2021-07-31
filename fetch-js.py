#!/usr/bin/env python

import requests
import sys
import re
import numpy as np 

target = sys.argv[1]
regex_word = "example" #Change this

print("[*] Trying to fetch js files")

proxy = {'http':'http://127.0.0.1:8080'}
ext_files = []

# Cleaning https
def return_files(target):
    files = []
    headers = {
                "User-Agent":"Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language":"en-US,en;q=0.5",
                }
    res = requests.get(target,headers=headers,timeout=10)
    match = re.findall("(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-&?=%.]+",res.text)
    x = lambda a: a if regex_word in a else False
    inscope = [ x(url) for url in match ]
    inscope = list(filter(bool,inscope))
    for url in inscope:
        if url.startswith("http"):
            files.append(url)
        if url.startswith("/"):
            files.append(target + url)
    return files

# Filtering out filetypes like js,txt,json
def scrape_filetypes(arr_of_files):
    ext = [".js",".txt",".json",".conf",".html",".php",".pdf"]
    for url in arr_of_files:
        for e in ext:
            ext_files.append(url) if e in url else False


def send_request_to_burp(arr_of_files):
    headers = {
                "User-Agent":"Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language":"en-US,en;q=0.5",
                }
    for request in arr_of_files:
        requests.get(request,headers=headers,proxies=proxy,timeout=10)

def run_as_requested(depth=3):
    dataset = []
    files = return_files(target)
    dataset = np.unique(files)
    scrape_filestypes(dataset)
    diff_array  = [x for x in dataset if x not in ext_files]
    for n in range(depth):
        for url in diff_array:
            files = return_files(url)
            dataset = np.unique(files)
            scrape_filetypes(dataset)
            diff_array = [x for x in dataset if x not in ext_files]

# Search through the files for more urls
def main():
    run_as_requested(1)
    print("[+] Found {} files to work on".format(len(ext_files)))
    for url in ext_files: print(url)
    send_request_to_burp(ext_files)
    sys.exit()

main()
