#!/bin/bash

# Define Some BASES
# ~~~~~~~~~~~~~~~~~

    BASE_DN="dc=REPLACE,dc=ME"
    BASE_DEFAULTS="cn=fetchmailDefaults,ou=Templates,${BASE_DN}"
    BASE_USERS="ou=Zarafa,${BASE_DN}"

# Filter of 'fetchmail' attributes
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    FETCHMAIL_FILTER="fetchmailUsername fetchmailPassword fetchmailServer fetchmailProtocol fetchmailSSL fetchmailEnabled fetchmailCustom"

# This is getting filled later
# and passed to fetchmail
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    FETCH_THIS=""

# Save result of 'ldapsearch' into buffer variable
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    DEFAULTS_BUFFER=$(ldapsearch -xLLL -b ${BASE_DEFAULTS} ${FETCHMAIL_FILTER})

# Get and Set Defaults
# ~~~~~~~~~~~~~~~~~~~

    default_Server=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailServer" | cut -d' ' -f2)
    default_Protocol=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailProtocol" | cut -d' ' -f2)
    default_SSL=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailSSL" | cut -d' ' -f2)
    default_Custom=$(<<< "${DEFAULTS_BUFFER}" grep "^fetchmailCustom" | cut -d' ' -f2)


# Save user search results
# into a new buffer variable
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    USER_BUFFER=$(ldapsearch -xLLL -b ${BASE_USERS} uid=* dn | sed 's/dn: //g')

# Get settings of a user
# ~~~~~~~~~~~~~~~~~~~~~~

    for user in ${USER_BUFFER}; do

        # Save user-attributes search results
        # into a new buffer variable
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        VALUE_BUFFER=$(ldapsearch -xLLL -b ${user} mail ${FETCHMAIL_FILTER} | grep -v 'dn')

        # If fetchmail not enabled we can
        # return the loop here
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        user_Enabled=$(<<< "${VALUE_BUFFER}" grep "^fetchmailEnabled" | cut -d' ' -f2)
        [[ ${user_Enabled} == "FALSE" ]] && continue


        # Store additional attributes
        # in seperate variables
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~

        user_Username=$(<<< "${VALUE_BUFFER}" grep "^fetchmailUsername" | cut -d' ' -f2)
        user_Password=$(<<< "${VALUE_BUFFER}" grep "^fetchmailPassword" | cut -d' ' -f2)
        user_Server=$(<<< "${VALUE_BUFFER}" grep "^fetchmailServer" | cut -d' ' -f2)
        user_Protocol=$(<<< "${VALUE_BUFFER}" grep "^fetchmailProtocol" | cut -d' ' -f2)
        user_SSL=$(<<< "${VALUE_BUFFER}" grep "^fetchmailSSL" | cut -d' ' -f2)
        user_Custom=$(<<< "${VALUE_BUFFER}" grep "^fetchmailCustom" | cut -d' ' -f2)
        user_Mail=$(<<< "${VALUE_BUFFER}" grep "^mail" | cut -d' ' -f2)

        # Compare default- and user-attributes
        # and set the required values
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        [[ "x${user_Server}" == "x" ]] && user_Server=$default_Server
        [[ "x${user_Protocol}" == "x" ]] && user_Protocol=$default_Protocol
        [[ "x${user_SSL}" == "x" ]] && user_SSL=$default_SSL
        [[ "x${user_Custom}" == "x" ]] && user_Custom=$default_Custom

        [[ "${user_SSL}" == "TRUE" ]] && user_SSL="ssl"

        # Generate the configuration lines that
        # will be piped to fetchmail
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        FETCH_THIS="poll ${user_Server} proto ${user_Protocol} user ${user_Username} pass ${user_Password} is ${user_Mail} here ${user_Custom} ${user_SSL}\n${FETCH_THIS}"

    done

# Done (use -e to parse \n)
# ~~~~~~~~~~~~~~~~~~~~~~~~~

    echo -e "$FETCH_THIS"
