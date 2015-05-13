#!/bin/bash

# Define BASE
# ~~~~~~~~~~~~~~~~~

    BASE_DN="ou=Users,dc=foo,dc=bar"

# Filter of 'fetchmail' attributes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    FETCHMAIL_FILTER="fetchmailUsername fetchmailPassword fetchmailServer fetchmailProtocol fetchmailSSL fetchmailEnabled fetchmailCustom"

# This is getting filled later
# and passed to fetchmail
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    FETCH_THIS=""

# Save result of 'ldapsearch' into buffer variable
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #DEFAULTS_BUFFER=$(ldapsearch -xLLL -b ${BASE_DEFAULTS} ${FETCHMAIL_FILTER})

# Get and Set Defaults
# ~~~~~~~~~~~~~~~~~~~

    #default_Server=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailServer" | cut -d' ' -f2)
    #default_Protocol=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailProtocol" | cut -d' ' -f2)
    #default_SSL=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailSSL" | cut -d' ' -f2)
    #default_Custom=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailCustom" | cut -d' ' -f2)


# Save user search results
# into a new buffer variable
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    USER_BUFFER=$(ldapsearch -xLLL -b ${BASE_DN} uid=* dn | sed 's/dn: //g')

# Get settings of a user
# ~~~~~~~~~~~~~~~~~~~~~~

    for user in ${USER_BUFFER}; do
		
		MAILADDR_BUFFER=$(ldapsearch -xLLL -b ${user}  mail)
		user_Mail=$(<<< "${MAILADDR_BUFFER}" grep "^mail" | cut -d' ' -f2)
		
		ACCOUNT_BUFFER=$(ldapsearch -xLLL -b ${user} -s sub fetchmailUsername=* sn | grep ^sn | sed 's/sn: //g')
		
		for account in ${ACCOUNT_BUFFER}; do
			
			# # Save user-attributes search results
			# # into a new buffer variable
			# # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

			VALUE_BUFFER=$(ldapsearch -xLLL -b "sn="${account}","${user} -s sub ${FETCHMAIL_FILTER} | grep -v 'dn')

			# # If fetchmail not enabled we can
			# # return the loop here
			# # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

			user_Enabled=$(<<< "${VALUE_BUFFER}" grep "^fetchmailEnabled" | cut -d' ' -f2)
			[[ ${user_Enabled} == "FALSE" ]] && continue


			# # Store additional attributes
			# # in seperate variables
			# # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

			user_Username=$(<<< "${VALUE_BUFFER}" grep "^fetchmailUsername" | cut -d' ' -f2)
			user_Password=$(<<< "${VALUE_BUFFER}" grep "^fetchmailPassword" | cut -d' ' -f2)
			user_Server=$(<<< "${VALUE_BUFFER}" grep "^fetchmailServer" | cut -d' ' -f2)
			user_Protocol=$(<<< "${VALUE_BUFFER}" grep "^fetchmailProtocol" | cut -d' ' -f2)
			user_SSL=$(<<< "${VALUE_BUFFER}" grep "^fetchmailSSL" | cut -d' ' -f2)
			user_Custom=$(<<< "${VALUE_BUFFER}" grep "^fetchmailCustom" | cut -d' ' -f2)
			
			[[ "${user_SSL}" == "TRUE" ]] && user_SSL="ssl"

			# # Generate the configuration lines that
			# # will be piped to fetchmail
			# # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

			FETCH_THIS="poll ${user_Server} proto ${user_Protocol} user ${user_Username} pass ${user_Password} is ${user_Mail} here ${user_Custom} ${user_SSL}\n${FETCH_THIS}"
			
			VALUE_BUFFER=""
			
		done
		
		ACCOUNT_BUFFER=""

    done

# Done (use -e to parse \n)
# ~~~~~~~~~~~~~~~~~~~~~~~~~

    echo -e "$FETCH_THIS"
