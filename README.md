# netbird-kerb

Scripts to automate generating a Kerb token when connected to Red Hat Netbird VPN.

## Generate keytab

```bash
ktutil
-> addent -password -p gahealy@IPA.REDHAT.COM -k 1 -e aes256-cts-hmac-sha1-96 -f
-> wkt /Users/gahealy/.kerberos.gahealy.keytab
-> quit

klist -kte ~/.kerberos.gahealy.keytab
kinit -n @IPA.REDHAT.COM -c FILE:$HOME/.krb5cc_gahealy
kinit -T FILE:$HOME/.krb5cc_gahealy -k -t ~/.kerberos.gahealy.keytab gahealy@IPA.REDHAT.COM
```

## Install

```bash
mkdir -p ~/bin
cp bin/netbird-kinit.sh ~/bin/netbird-kinit.sh
cp Library/LaunchAgents/com.gahealy.netbird-kinit.plist ~/Library/LaunchAgents/com.gahealy.netbird-kinit.plist
```