# recon-scripts
A simple script to automate the process of asset discovery using different open source tools. Feel free to use different set of wordlists according to your convenience.

## Usage
- Setup a VPS to make all the installation (DigitalOcean - Preferred)
- Create free account on [censys](https://censys.io/), get the API and SECRET key and add it into the script
- Make sure to add install_tools in the main function.
- Use different subdomain wordlists like all.txt ~ Jhaddix or assetnote [wordlists](https://wordlists.assetnote.io/).
- Edit the cron.sh file to add the location of your target dir
- Also edit the provider-config.yml file of [notify](https://github.com/projectdiscovery/notify) project
```
# mkdir target.com && mv automate.sh target.com
# ./cron.sh target.com
```

## TODO
- Add a cron job to run the script alteast twice a day
- Subdomain takeover function to be implemented
