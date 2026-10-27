#!/usr/bin/env bash
#--------------------------------------------------------------------------------
# File:          update-morrorlist.sh
# Created:       Wednesday, 06 May 2026 - 08:03 AM
# Author:        AhmdHosni (ahmdhosny@gmail.com)
# Link:
# Description:
#--------------------------------------------------------------------------------

# sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
#

# #!/bin/bash
# sudo reflector \
#     --country 'Germany,France,Netherlands' \
#     --latest 20 \
#     --protocol https \
#     --sort rate \
#     --connection-timeout 10 \
#     --download-timeout 10 \
#     --save /etc/pacman.d/mirrorlist
#
#
#

sudo reflector \
    --verbose \
    --country 'Germany,France,Netherlands' \
    --latest 20 \
    --protocol https \
    --sort rate \
    --connection-timeout 10 \
    --save /etc/pacman.d/mirrorlist
