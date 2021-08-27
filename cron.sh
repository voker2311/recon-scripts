#!/bin/bash
target=$1

if [[ $# -eq 0 ]];then                                                                                                                                                                        
        echo "[-] Usage: ./cron.sh <target.com>"                                           
        exit 1;                                                                                
fi

location="target_dir" # Change this
cd $location

# Place automate.sh in target_dir
./automate.sh $target

if [ ! -d $location/subslive ];then
       mkdir subslive
fi
ulimit -n 524288
sleep 200
# Perform dnsgen on final.txt
cd $location/dnsgen-output
dnsgen final.txt > subs1.txt
dnsgen --wordlist /opt/altdns/words.txt final.txt > subs2.txt
cat subs1.txt subs2.txt | sort -u > total.txt
shuffledns -silent -d $target -list total.txt -r /opt/massdns/lists/resolvers.txt > resolved.txt
sleep 100
mv resolved.txt final.txt

cat $location/dnsgen-output/final.txt | anew $location/subslive/subdomains.txt > $location/subslive/diff.txt

if [ -s $location/subslive/diff.txt ]; then
        notify -silent -data $location/subslive/diff.txt -bulk # Configure the provider according to your convinience
fi
