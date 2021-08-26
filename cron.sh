#!/bin/bash
target=$1

if [[ $# -eq 0 ]];then                                                                                                                                                                        
        echo "[-] Usage: ./cron.sh <target.com>"                                           
        exit 1;                                                                                
fi

location="location_to_target_dir" # Change this
cd $location

# Place automate.sh in target_dir
./automate.sh $target

if [ ! -d $location/subslive ];then
       mkdir subslive
fi

cp $location/dnsgen-output/final.txt | anew subslive/subdomains.txt > $location/subslive/diff.txt

if [ -s $location/subslive/diff.txt ]; then
        notify -silent -data $location/subslive/diff.txt -bulk # Configure the provider according to your convinience
fi
