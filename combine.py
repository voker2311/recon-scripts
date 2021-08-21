#!/usr/bin/env python
import sys

file = open(sys.argv[2])
domain = sys.argv[1]

for word in file.readlines():
    subdomain = word.strip() + "." + domain
    print(subdomain)
