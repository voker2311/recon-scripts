# recon-scripts
A simple script to automate the process of asset discovery using different open source tools. Feel free to use different set of wordlists according to your convenience.
## Various functions
```sh
▶ install_tools - Install all the tools necessary to run the script
▶ censys_api - Scrape SSL Certificates from Censys API
▶ subdomain_discovery - Discover subdomains using tools like findomain,subfinder,amass, etc
▶ bruteforce - Resolving subdomains created using combine.py (Try with different wordlists)
▶ dnsgen - Performing permutations using words like dev,test,staging, etc
▶ extract_ips - Extract IPs from Censys API related to the target domain/subdomain
```
## Usage
- Setup a VPS to make all the installation (DigitalOcean - Preferred)
- Create free account on [censys](https://censys.io/), get the API and SECRET key and add it into the script
- Make sure to add install_tools in the main function.
- Use different subdomain wordlists like all.txt ~ Jhaddix or assetnote [wordlists](https://wordlists.assetnote.io/).
- Edit the cron.sh file to add the location of your target dir
- Also edit the provider-config.yml file of [notify](https://github.com/projectdiscovery/notify) project
```sh
▶ mkdir target.com && mv automate.sh target.com
▶ ./cron.sh target.com
```

## TODO
- Subdomain takeover function to be implemented
