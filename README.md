# fetchmail-ldap

OpenLDAP schema to dynamically generate a configuration file to poll mails via `fetchmail` .

# Attributes

 * `fetchmailEnabled ` >> `TRUE` or `FALSE` - used to deteced if the entry should be parsed or not
 * `fetchmailServer  ` >> DNS-Name of the Mailserver (but also works with IP-Addresses)
 * `fetchmailProtocol` >> e.g. `pop3`, `imap` or any other protocol supported by fetchmail
 * `fetchmailUsername` >> Username of the mailbox you're connecting to
 * `fetchmailPassword` >> same as above
 * `fetchmailCustom  ` >> add any additionial commands like `nokeep fetchall`
 * `fetchmailSSL     ` >> `TRUE` or `FALSE` - set this to enable SSL support

# Expected DIT

My tree looks like this:

```
dc=foo,dc=bar
|_ ou=Users
   |_ uid=testuserA
		|_ mail = testuserA@myserver.com
		|_ sn=accountA
		|	|_ fetchmailServer = pop.providerA.de
		|	|_ fetchmailProtocol = pop3
		|	|_ fetchmailCustom = nokeep fetchall
		|	|_ fetchmailSSL = true
		|	|_ fetchmailUsername = testuserA@providerA.de
		|	|_ fetchmailPassword = secretA
		|	|_ fetchmailEnabled = true
		|	|_ sn = accountA
		|	|_ objectClass = top, inetOrgPerson, fetchmail
		|_ sn=accountB
		|	|_ fetchmailServer = imap.providerB.de
		|	|_ fetchmailProtocol = imap
		|	|_ fetchmailCustom = fetchall
		|	|_ fetchmailSSL = false
		|	|_ fetchmailUsername = testuserA@providerB.de
		|	|_ fetchmailPassword = secretB
		|	|_ fetchmailEnabled = true
		|	|_ sn = accountB
		|	|_ objectClass = top, inetOrgPerson, fetchmail
	|_ uid=testuserB
		|_ mail = testuserB@myserver.com
		|_ sn=fooAccount
		|	|_ fetchmailServer = pop.providerA.de
		|	|_ fetchmailProtocol = pop3
		|	|_ fetchmailCustom = nokeep fetchall
		|	|_ fetchmailSSL = true
		|	|_ fetchmailUsername = testuserB@providerA.de
		|	|_ fetchmailPassword = secretC
		|	|_ fetchmailEnabled = true
		|	|_ sn = accountA
		|	|_ objectClass = top, inetOrgPerson, fetchmail
```

This will generate the following line that will be passed to fetchmail:

`poll pop.providerA.de proto pop3 user testuserA@providerA.de pass secretA is testuserA@myserver.com here nokeep fetchall ssl`
`poll imap.providerB.de proto imap user testuserA@providerB.de pass secretB is testuserA@myserver.com here fetchall`
`poll pop.providerA.de proto pop3 user testuserB@providerA.de pass secretC is testuserB@myserver.com here nokeep fetchall ssl`

# Add Schema

#### Method 1:

add this line to `/etc/ldap/slapd.conf`:
`include /etc/ldap/schema/fetchmail.schema`

#### Method 2:

`ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/ldap/schema/fetchmail.ldif`

# Edit Settings
### fetchmail.sh

Change

 * `BASE_DN`

that it fits your LDAP configuration.

# Test it!

Run `fetchmail.sh` and take a look at the output - it should be similiar to the `poll ...` line.

If everything fine setup a Cronjob to invoke the script:

`*/5 * * * * /usr/local/bin/fetchmail.sh | fetchmail -f -`

# Developers Homepage

Vist: http://leckerbeef.de/fetchmail-ldap-integration/
