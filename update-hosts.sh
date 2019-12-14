#!/bin/sh

## Clean up any stale tempfile
echo "Removing old files..."
[ -f /tmp/hosts.working ] && rm -f /tmp/hosts.working

## Awk regex to be inverse-matched as whitelist
whitelist='(upgrade.spotify.com|desktop.spotify.com|api.solvemedia.com|maker.ifttt.com|satellite.ifttt.com|mobile-api.ifttt.com|buffalo-ios.ifttt.com|assets.ifttt.com|open.spotify.com|intuit.com)'

## URLs of Ad Blacklists to Use (Choose only one of the below options)
# Only MVP
blacklist='https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts http://winhelp2002.mvps.org/hosts.txt https://raw.githubusercontent.com/jerryn70/GoodbyeAds/master/Hosts/GoodbyeAds.txt'

# Only pgl yoyo
#blacklist='http://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext'

# All Blacklists
#blacklist='http://winhelp2002.mvps.org/hosts.txt http://pgl.yoyo.org/as/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext https://adaway.org/hosts.txt'

## Fetch all Blacklist Files
echo "Fetching Blacklists..."
for url in $blacklist; do
    curl --silent $url >> "/tmp/hosts.working"
done

## Process Blacklist, Eliminiating Duplicates, Integrating Whitelist, and Converting to unbound format
echo "Processing Blacklist..."
awk -v whitelist="$whitelist" '$1 ~ /^127\.|^0\./ && $2 !~ whitelist {gsub("\r",""); print tolower($2)}' /tmp/hosts.working | sort | uniq | \
awk '{printf "server:\n", $1; printf "local-data: \"%s A 0.0.0.0\"\n", $1}' > /var/unbound/ad-blacklist.conf

## Original Proccess CMD
#awk -v whitelist="$whitelist" '$1 ~ /^127\.|^0\./ && $2 !~ whitelist {gsub("\r",""); print tolower($2)}' /tmp/hosts.working | sort | uniq | \
#awk '{printf "local-zone: \"%s\" redirect\n", $1; printf "local-data: \"%s. A 0.0.0.0\"\n", $1}' > /etc/unbound/ad-blacklist.conf

# Make unbound reload config to activate the new blacklist
#echo "Restarting unbound..."
#exec /etc/init.d/unbound reload

# Clean up tempfile
echo "Cleaning Up..."
rm -f '/tmp/hosts.working'
echo "Done. Please Restart the DNS Resolver service from the WebUI."
