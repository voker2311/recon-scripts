#!/bin/bash

target=$1

if [[ $# -eq 0 ]];then
	echo -e "\e[31m[-] Please provide something to scan\e[0m"
	echo -e "\e[31m[-] Usage: ./recon.sh <example.com>\e[0m"
	exit 0
fi

startup_script(){
	if [ ! -d recon-files ];then
		echo -e "\e[33m[*] Setting up a directory for recon files... [0%]\e[0m"
		mkdir recon-files
	fi
}

subdomain_discovery(){
	# Subdomain discovery starts from here
	# Using findomain tool
	echo -e "\e[33m[*] Scan started (Make sure that the filename will be saved based on the target name given) [5%]\e[0m"
	findomain=$(findomain -t "$target" --quiet | tee "recon-files/$target-findomain.txt" 2>/dev/null)
	sleep 0.3
	echo -e "\e[32m[*] Starting with subfinder tool\e[0m"
	subfinder=$(subfinder -silent -d "$target" -t 15 -o "recon-files/$target-domains.txt" 2>/dev/null)
	# Recursive one (Third level subdomain/domain if any)
	subfinder_recursive=$(subfinder -silent -d "$target" -t 10 -o "recon-files/$target-recursive-domains.txt" -recursive 2>/dev/null)
	sleep 0.3
	echo -e "\e[32m[*] Amass scan started\e[0m"
	amass=$(amass enum -d "$target" -o "recon-files/$target-amass-scan.txt" 2>/dev/null)
	# Using crt.sh to get another set of subdomains
	# Hope you have provided a domain without http/https
	crt_sh=$(curl -s "https://crt.sh/?q=$target&output=json" | jq .[].name_value | tr '"' ' ' | awk '{gsub(/\\n/,"\n")}1' | awk '{print $1}' | sort -u | tee "recon-files/$target-crt-domains.txt" 2>/dev/null)
	cat recon-files/*.txt | sort -u > recon-files/subdomains.final
	# Done with everything
	echo -e "\e[32m[+] Subdomain discovery completed... [27%]\e[0m"
}

http_discovery(){
	# Discovering alive HTTP sites
	echo -e "\e[36m[*] Using httpx tool from project discovery [40%]\e[0m"
	httpx -l recon-files/subdomains.final -silent -status-code -content-length -o recon-files/httpx-alive-urls.txt 2>/dev/null
	sleep 0.3
}


fetch_nuclei_scripts(){
	# Using basic nuclei scripts like .git,.env,robots.txt,conf files
	if [ ! -d nuclei-scripts ];then
		echo -e "\e[36m[*] Nuclei scripts will stored in nuclei-scripts [49%]\e[0m"
		mkdir nuclei-scripts
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/configs/git-config.yaml" -O nuclei-scripts/git.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/configs/docker-compose-config.yaml" -O nuclei-scripts/docker.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/files/ds_store.yaml" -O nuclei-scripts/ds_store.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposures/tokens/google/oauth-access-key.yaml" -O nuclei-scripts/oauth-key.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposed-panels/django-admin-panel.yaml" -O nuclei-scripts/django-admin.yaml
		wget --quiet "https://raw.githubusercontent.com/projectdiscovery/nuclei-templates/master/exposed-panels/wordpress-login.yaml" -O nuclei-scripts/wordpress-login.yaml
		echo -e "\e[35m[*] Make sure to check others on httpx official github repo [56%]\e[0m"
	fi
}

execute_nuclei_scripts(){
	# Using for loop to get all the yaml files
	for i in $(ls nuclei-scripts/*.yaml);do
		file=$(echo "$i" | awk -F\. '{print $1}')
		nuclei -l recon-files/httpx-alive-urls.txt -t $i -o recon-files/$file-output.txt 2>/dev/null
		sleep 0.3;
	done
}

wayback_for_everyone(){
	# Getting wayback archives for each domain
	if [ ! -d wayback-urls ];then
		echo -e "\e[36m[*] Waaybackkkk OK... [67%]\e[0m"
		mkdir wayback-urls
	fi
	for i in $(cat recon-files/subdomains.final);do
		waybackurls $i > wayback-urls/$i-wayback.url
		sleep 0.1;
	done
	echo -e "\e[36m[*] Wanna try out with gau tool? Reply with y/n: \e[0m"
	read reply
	if [ "$reply" == "y" ] || [ "$reply" == "Y" ];then
		gau_if_required
	fi
}

gau_if_required(){
	# Same technique as that of waybackurls
	if [ ! -d gau_tool_files ];then
		echo -e "\e[36m[*] You asked for gau, here I am.. :) [78%]\e[0m"
		sleep 3.5
		mkdir gau_tool_files
		for i in $(cat recon-files/subdomains.final);do
			gau -t 2 -o gau_tool_files/$i-gau.url $i
			sleep 0.1;
		done
	fi
}

echo -e "\e[36mScript started at `date`\e[0m"
# Startup script
startup_script
#subdomain discovery
subdomain_discovery
# Sleeping for a bit
sleep 3
# Http discovery (Filtering alive targets)
http_discovery


echo -e "\e[36m[*] Interested in basic nuclei recon. (Y/N)\e[0m"
read reply
if [ "$reply" == "Y" ] || [ "$reply" == "y" ];then
	# Fetching nuclei scripts
	fetch_nuclei_scripts
	sleep 0.5
	# Executing each of them (Basic files)
	execute_nuclei_scripts
fi

# Wayback discovery
wayback_for_everyone

echo -e "\e[32m[+] Done, check your files in the recon folder [100%]\e[0m"
echo -e "\e[32m[+] Script finished at `date`\e[0m"
