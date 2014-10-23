# fetchmail-ldap

OpenLDAP schema to dynamically generate a configuration file to poll mails via `fetchmail` .

# Attributes

 * `fetchmailEnabled` >> `TRUE` or `FALSE` - used to deteced if the entry should be parsed or not
 * `fetchmailServer` >> DNS-Name of the Mailserver (but also works with IP-Addresses)
 * `fetchmailProtocol` >> e.g. `pop3`, `imap` or any other protocol supported by fetchmail
 * `fetchmailUsername` >> Username of the mailbox you're connecting to
 * `fetchmailPassword ` >> same as above
 * `fetchmailCustom` >> add any additionial commands like `nokeep fetchall`
 * `fetchmailSSL` >> `TRUE` or `FALSE` - set this to enable SSL support

# Expected DIT

Basically you should have two Trees:

 * one with the global settings used for each individual user, like `fetchmailServer`, `fetchmailProtocol` and `fetchmailCustom`
 * another tree with the actual users (should be `inetOrgPerson`). These must have at least added `fetchmail` to `ObjectClass` and a valid `mail` attribute. Usually you also add the attributes `fetchmailUsername` and `fetchmailPassword`
 
So the tree looks like:

```
dc=foo,dc=bar
|_ ou=Templates 
|  |_ cn=fetchmailDefaults
|     |_ fetchmailServer = pop.myserver.com
|     |_ fetchmailProtocol = pop3
|     |_ fetchmailCustom = nokeep fetchall
|     |_ fetchmailSSL = true
|     |_ sn = Fetchmail Default Values
|     |_ objectClass = top, inetOrgPerson, fetchmail
|_ ou=Users
   |_ uid=testuser
      |_ mail = testuser@myserver.com
      |_ fetchmailUsername = testuser
      |_ fetchmailPassword = topSecret
      |_ fetchmailSSL = false <-- This would overwrite the Default-Settings
```

This will generate the following line that will be passed to fetchmail:

`poll pop.myserver.com proto pop3 user testuser pass toSecret is testuser@myserver.com here nokeep fetchall ssl`

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
 * `BASE_DEFAULTS`
 * `BASE_USERS`

that it fits your LDAP configuration.

# Test it!

Run `fetchmail.sh` and take a look at the output - it should be similiar to the `poll ...` line.

If everything fine setup a Cronjob to invoke the script:

`*/5 * * * * /usr/local/bin/fetchmail.sh | fetchmail -f -`

# Developers Homepage

Vist: http://leckerbeef.de/fetchmail-ldap-integration/
