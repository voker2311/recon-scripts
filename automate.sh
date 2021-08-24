#!/bin/bash

TARGET=$1
HOME=$(pwd)

if [[ $# -eq 0 ]];then
        echo "[-] Usage: ./automate.sh <target.com>"
        exit 1;
fi

install_tools(){
	# Get findomain
	wget --quiet https://github.com/Findomain/Findomain/releases/download/5.0.0/findomain-linux -O findomain && mv findomain /usr/local/bin
       	# Get subfinder
	GO111MODULE=on go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
	# Get amass
	apt install amass
	# Get jq
	apt install jq
	# Get assetfinder
	go get -u github.com/tomnomnom/assetfinder
	# Get massdns
	cd /opt && git clone https://github.com/blechschmidt/massdns.git
	cd massdns && make
	cp /opt/massdns/bin/massdns /usr/bin/massdns
	# Get shuffledns
	GO111MODULE=on go get -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
	# Get dnsgen
	pip3 install dnsgen
	cp /root/go/bin/* /usr/local/bin
}

wrapper_for_files(){
	cd $HOME
	mkdir ip-based recon-files wordlist-making dnsgen-output censys-results altdns-output
	wget --quiet https://raw.githubusercontent.com/Voker2311/recon-scripts/main/combine.py -O $HOME/wordlist-making/combine.py
}

censys_api(){
	cd $HOME/censys-results
	API_KEY="api_key" # Change this
	SECRET="secret_key" # Change this
	curl -s -X POST https://search.censys.io/api/v1/search/certificates -u $API_KEY:$SECRET -d "{\"query\":\"$TARGET\"}" | jq .results[] | grep subject_dn | grep -oE "CN=.*" | awk -F\" '{print $1}' | awk -F\= '{print $2}' | grep -v "*" | sort -u | grep -i "$TARGET" > censys-out.txt
	shuffledns -silent -d "$TARGET" -list censys-out.txt -r /opt/massdns/lists/resolvers.txt > resolved.txt
}

subdomain_discovery(){
	cd $HOME/recon-files
	findomain --quiet -t "$TARGET" > findomain.txt
	subfinder -silent -d "$TARGET" -t 15 > subdomains.txt
	subfinder -silent -d "$TARGET" -t 10 > recursive-domains.txt
	amass enum -d "$TARGET" -passive > amass.txt
	curl -s "https://crt.sh/?q=$TARGET&output=json" | jq .[].name_value | tr '"' ' ' | awk '{gsub(/\\n/,"\n")}1' | awk '{print $1}' | sort -u > crt.txt
	assetfinder "$TARGET" > assets.txt
	cat *.txt | sort -u > discovery.subs
	shuffledns -silent -d "$TARGET" -list discovery.subs -r /opt/massdns/lists/resolvers.txt > resolved.txt
	echo "[+] Check subdomains in recon-files"
}

bruteforce(){
	# Bruteforcing DNS names
	echo "[*] Bruteforcing DNS, this might take a while"
	echo "[:)] Go grab a coffee"
	cd $HOME/wordlist-making
	wget --quiet https://wordlists-cdn.assetnote.io/data/manual/2m-subdomains.txt
	#wget https://wordlists-cdn.assetnote.io/data/manual/best-dns-wordlist.txt
	echo "[*] Checking the existence of combine.py"
	if [ -f "combine.py" ];then
		echo "[+] Started with 2m subdomains.."
		python3 combine.py "$TARGET" "2m-subdomains.txt" > list1.txt
		sleep 5
		#python combine.py $TARGET "best-dns-wordlist.txt" > list2.txt
		cat list1.txt | sort -u > total-subs.txt
		shuffledns -silent -d "$TARGET" -list total-subs.txt -r /opt/massdns/lists/resolvers.txt > resolved.txt
		rm 2m-subdomains.txt list1.txt total-subs.txt
	else
		echo "[-] File not found"
		exit 1;
	fi
}

dnsgen(){
	cd $HOME/dnsgen-output
	cp $HOME/wordlist-making/resolved.txt 1.txt
	cp $HOME/recon-files/resolved.txt 2.txt
	cp $HOME/censys-results/resolved.txt 3.txt
	cat * | sort -u | grep "$target" > final.txt
	rm 1.txt 2.txt 3.txt
	#dnsgen final.txt > permutations.txt
	#resolve_subs
}

altdns(){
	cd $HOME/altdns-output
	cp $HOME/dnsgen-output/final.txt .
	altdns -i final.txt -o permutations -w /opt/altdns/words.txt -r -s altdns_output.txt
}

resolve_subs(){
	cd $HOME/dnsgen-output
	/opt/massdns/bin/massdns -r /opt/massdns/lists/resolvers.txt -t A -q -o S permutations.txt > dnsgen-resolved.txt
	cp dnsgen-resolved.txt $HOME/subs.txt
}

extract_ips(){
	cd $HOME/ip-based
	cp $HOME/dnsgen-output/final.txt .
	cat final.txt | grep "$TARGET" > temp.txt
	mv temp.txt final.txt
	echo "[*] Domains names -> IP Addresses"
	for i in `cat final.txt`;do
		dig +short +recurse A $i;
	done | grep -oE "[0-9]{1,3}.+" | grep -v "[a-z]" | sort -u > ips.txt
	# Getting list of ips from censys.io
	echo "[*] Getting the list of ips associated to the target from censys"
	API_KEY="api_key" # Change this
	SECRET="secret_key" # Change this
	count=$(curl -s -u "$API_KEY":"$SECRET" -H 'Content-Type: application/json' "https://search.censys.io/api/v2/hosts/search?q=$TARGET&per_page=100" | jq -r .result.total)
	iters=$(expr "$count" / 100 + 1)
	cursor=""
	for ((i = 1 ; i <= "$iters" ; i++));do
		curl -s -u "$API_KEY":"$SECRET" -H 'Content-Type: application/json' "https://search.censys.io/api/v2/hosts/search?q=$TARGET&per_page=100&cursor=$cursor" | jq -r .result.hits[].ip >> ips.txt
		next=$(curl -s -u "$API_KEY":"$SECRET" -H 'Content-Type: application/json' "https://search.censys.io/api/v2/hosts/search?q=$TARGET&per_page=100&cursor=$cursor" | jq -r .result.links.next)
		if [[ ! -z "$next" ]];then
			cursor=$next
		fi			
	done
	cat ips.txt | sort -u > final-ips.txt
}

main(){
	start_time=$(date "+%T")
	epoch1=$(date "+%s" -d $start_time)
	echo "[+] Scan started at $start_time"
	#install_tools
	echo "[*] Setting up the files"
	wrapper_for_files
	echo "[*] Subdomain discovery.."
	subdomain_discovery
	echo "[*] Fetching contents from censys api.."
	censys_api
	echo "[*] Bruteforcing using assetnote wordlist.."
	bruteforce
	echo "[*] Performing permutations on the subdomains found.."
	dnsgen
	echo "[*] Extracting IP Addresses"
	extract_ips
	echo "[*] Run naabu tool on the list of ips"
	#echo "[*] Using altdns to generate words with dev,staging,etc"
	#altdns
	end_time=$(date "+%T")
	epoch2=$(date "+%s" -d $end_time)
	tots=`expr $epoch2 - $epoch1`
	echo "[+] Scan completed in "$tots" secs"
}

extract_ips
