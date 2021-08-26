#!/bin/bash

target="target.com"
location="location_to_target_dir" # Change this
cd $location

# Place automate.sh in target_dir
$location/automate.sh $target

if [ ! -d $location/subslive ];then
       mkdir subslive
fi

cp $location/dnsgen-output/final.txt | anew subslive/subdomains.txt > $location/subslive/diff.txt

if [ -s $location/subslive/diff.txt ]; then
        notify -silent -data $location/subslive/diff.txt -bulk # Configure the provider according to your convinience
fi
