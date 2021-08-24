# recon-scripts
A simple script to automate the process of asset discovery using different open source tools. Feel free to use different set of wordlists according to your convenience.

## Usage
- Setup a VPS to make all the installation (DigitalOcean - Preferred) 
- Make sure to add install_tools in the main function.
- Use different subdomain wordlists like all.txt ~ Jhaddix or assetnote [wordlists](https://wordlists.assetnote.io/).
```
mkdir target.com && cd target.com && ./automate.sh target.com
```

## TODO
- Add a cron job to run the script alteast twice a day
- Email based monitoring incase of new subdomain discovery
- Subdomain takeover function to be implemented
