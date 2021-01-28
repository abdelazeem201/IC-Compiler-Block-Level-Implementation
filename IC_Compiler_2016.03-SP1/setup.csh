#
# SYNOPSYS IC Compiler Workshop environment - model setup file
#

# The SYNOPSYS environment points to where the tool is installed
setenv SYNOPSYS  /tools/synopsys/icc/2016.03-sp1

# This variable needs to point to the license server
setenv SNPSLMD_LICENSE_FILE 27000@license_server

# Adjust exec path
set path = ($path $SYNOPSYS/bin )

# The following environment variable needs to point to the ICV location:
setenv ICV_HOME_DIR  <YOUR_ICV_INSTALLATION_DIRECTORY>

