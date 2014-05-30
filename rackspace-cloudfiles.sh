#!/bin/bash

#
# DESCRIPTION
#
# rackspace-cloudfiles.sh is a bash script that uses curl to interact with 
# Rackspace CloudFiles containers/objects using Rackspace Cloud Identity API 
# v1.1. 
#
# AUTHOR
#
# Michael Ryvkin <mryvkin@gyrocode.com>
#
# COPYRIGHT
#
# Copyright (c) 2013 Michael Ryvkin <mryvkin@gyrocode.com>
#
# LICENSE
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#


# =============================================================================
# CONFIGURATION: DEFAULT VALUES
# -----------------------------------------------------------------------------
AUTH_USER=
AUTH_KEY=

# Authentication URL
AUTH_URL_US=https://auth.api.rackspacecloud.com/v1.1/auth
AUTH_URL_LON=https://lon.auth.api.rackspacecloud.com/v1.1/auth
AUTH_URL=${AUTH_URL_US}

# Region
# ORD - Chicago
# DFW - Dallas
REGION=ORD

# Determines whether ServiceNet should be used
SERVICENET=N



# =============================================================================
# SCRIPT
# -----------------------------------------------------------------------------

VERSION=0.3

# As seen at http://www.commandlinefu.com/commands/view/4841/url-encode
uri_escape(){ local y; y="$@"; echo -n ${y/\\/\\\\} | while read -n1; do [[ $REPLY =~ [a-zA-Z0-9] ]] && printf "$REPLY" || printf "%%%X" \'"$REPLY"; done }


cf_put_container(){
   local container=$1

   if [[ -z ${QUIET} ]]; then
      echo -n "Creating container ${container}: "
   fi

   container=$(uri_escape ${container})

   http_code=$(
      curl -s -f -o /dev/null -X PUT -H "X-Auth-Token: ${AUTH_TOKEN}" \
      -w "%{http_code}" \
      "${ENDPOINT_URL}/${container}"
   )

   if [[ -z ${QUIET} ]]; then
      if [[ ${?} -ne 0 || !(${http_code} -ge 200 && ${http_code} -lt 300)  ]]; then
         echo -e "\e[1;31merror\e[0m"
      else
         echo -e "\e[1;32mOK\e[0m"
      fi
   fi
}


cf_put_object(){
   local container=$1
   local file=$(readlink -f $2)
   local file_dest=$3
   if [[ -n $3 ]]; then
       object=$3
   else
       object=${file}
   fi

   object=$(basename ${object})
   object=$(uri_escape ${object})

   container=$(uri_escape ${container})

   if [[ -e /sbin/md5 ]]; then
       local etag=$(md5 ${file}); etag=${etag##* }
       local ctype=$(file -bI ${file}); ctype=${ctype%%;*}
   else
       local etag=$(md5sum ${file}); etag=${etag%% *}
       local ctype=$(file -bi ${file}); ctype=${ctype%%;*}
   fi

   if [[ -z ${ctype} || ${ctype} == *corrupt* ]]; then
       ctype="application/octet-stream"
   fi

   if [[ -z ${QUIET} ]]; then
      echo -n "${file}: "
   fi

   http_code=$(
      curl -s -f -o /dev/null -X PUT -T ${file} -H "ETag: ${etag}" \
      -H "Content-Type: ${ctype}" -H "X-Auth-Token: ${AUTH_TOKEN}" \
      -w "%{http_code}" \
      "${ENDPOINT_URL}/${CONTAINER}/${object}"
   )

   if [[ -z ${QUIET} ]]; then
      if [[ ${?} -ne 0 || !(${http_code} -ge 200 && ${http_code} -lt 300)  ]]; then
         echo -e "\e[1;31merror\e[0m"
      else
         echo -e "\e[1;32mOK\e[0m"
      fi
   fi
}


help(){
   cat<<EOF
Usage: rackspace-cloudfiles.sh [options] [FILE] ...

Command-line interface to Rackspace Cloud Files for API v1.1

  -u USERNAME   username
  -k API_KEY    API key
  -a AUTH_URL   authentication URL
  -s            use ServiceNet
  -r            region (ORD, DRW, etc)
  -c CONTAINER  Cloud Files container
  -x REQUEST    request (PUT)
  -q            quiet mode
EOF
}


while getopts ":su:k:a:r:c:h:x:q" opt; do
  case $opt in
    s)
    SERVICENET=Y
    ;;
    u)
    AUTH_USER=$OPTARG
    ;;
    k)
    AUTH_KEY=$OPTARG
    ;;
    a)
    AUTH_URL=$OPTARG
    ;;
    r)
    REGION=$OPTARG
    ;;
    c)
    CONTAINER=$OPTARG
    ;;
    x)
    REQUEST=$OPTARG
    ;;
    q)
    QUIET=Y
    ;;
    h)
    help
    exit 0
    ;;
    \?)
    echo "ERROR: Invalid option: -$OPTARG" >&2
    help
    exit 1
    ;;
  esac
done
shift $((OPTIND-1))


ARGS=$@
if [[ -z ${ARGS} && !(${REQUEST} == "PUT" && -n ${CONTAINER}) ]]; then
   if [[ -z ${QUIET} ]]; then
      help
   fi
   exit 0
fi

if [[ -z ${AUTH_USER} ]]; then
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: User name is not specified."
   fi
   exit 1
fi

if [[ -z ${AUTH_KEY} ]]; then
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: API key is not specified."
   fi
   exit 1
fi

if [[ -z ${AUTH_URL} ]]; then
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Authentication server is not specified."
   fi
   exit 1
fi

if [[ -z ${REQUEST} ]]; then
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Request is not specified."
   fi
   exit 1
fi

if [[ ${REQUEST} != "PUT" ]]; then
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Invalid request is specified."
   fi
   exit 1
fi

if [[ -z ${CONTAINER} ]]; then
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Storage container is not specified."
   fi
   exit 1
fi



XML_AUTH_REQ=$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<credentials xmlns="http://docs.rackspacecloud.com/auth/api/v1.1"
 username="$AUTH_USER"
 key="$AUTH_KEY" />
EOF
)

XML_AUTH_RESP=$(mktemp /tmp/rackspace_cloud_upload.XXXXXX);
curl -s -X POST -d "$XML_AUTH_REQ" -o ${XML_AUTH_RESP} \
   -H "Content-Type: application/xml" \
   -H "Accept: application/xml" \
   $AUTH_URL
if [[ ${?} -ne 0 ]]; then
   rm -f ${XML_AUTH_RESP}
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Unable to connect to authentication server."
   fi
   exit 1
fi


XML_ATTR_URL=publicURL
if [[ ${SERVICENET} == Y || ${SERVICENET} == y ]]; then
   XML_ATTR_URL=internalURL
fi


AUTH_TOKEN=$(echo -e "setns ns=http://docs.rackspacecloud.com/auth/api/v1.1\ncat /ns:auth/ns:token/@id" | xmllint -shell ${XML_AUTH_RESP} | grep -v '>' | grep -v -e '^\s-------$' | cut -f 2 -d "=" | tr -d \");
if [[ -z ${AUTH_TOKEN} ]]; then
   rm -f ${XML_AUTH_RESP}
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Invalid username or API key."
   fi
   exit 1
fi

ENDPOINT_URL=$(echo -e "setns ns=http://docs.rackspacecloud.com/auth/api/v1.1\ncat /ns:auth/ns:serviceCatalog/ns:service[@name='cloudFiles']/ns:endpoint[@region='$REGION']/@$XML_ATTR_URL" | xmllint -shell ${XML_AUTH_RESP} | grep -v '>' | grep -v -e '^\s-------$' | cut -f 2 -d "=" | tr -d \");
if [[ -z ${ENDPOINT_URL} ]]; then
   rm -f ${XML_AUTH_RESP}
   if [[ -z ${QUIET} ]]; then
      echo "ERROR: Unable to retrieve endpoint URL."
   fi
   exit 1
fi

rm -f ${XML_AUTH_RESP}


if [[ ${REQUEST} == "PUT" ]]; then

   # Create a container
   if [[ -n ${CONTAINER} && -z ${ARGS} ]]; then
      cf_put_container ${CONTAINER}
   fi

   # Create an object in container
   if [[ -n ${CONTAINER} && -n ${ARGS} ]]; then
      if [[ -z ${QUIET} ]]; then
         echo "Uploading to container ${CONTAINER} at ${REGION} data center:"
      fi

      for arg in $ARGS; do
          file=$(readlink -f ${arg})
          file_tar=
          file_dest=

          [[ -e ${file} ]] || {
              if [[ -z ${QUIET} ]]; then
                 echo "ERROR: $file does not exist."
              fi
              continue
          }
          [[ -f ${file} || -d ${file} ]] || {
              if [[ -z ${QUIET} ]]; then
                 echo "ERROR: $file is not file or directory."
              fi
              continue
          }
          if [[ -d ${file} ]]; then
              is_dir=1
              if [[ -w ./ ]]; then
                  tardir="."
              else
                  tardir=/tmp
              fi

              file_tar=${tardir}/${arg}-cf-tarball.tar.gz
              file_dest=${arg}.tar.gz

              tar czf ${file_tar} ${arg}
              if [[ ${?} -ne 0 ]]; then
                  if [[ -z ${QUIET} ]]; then
                     echo "ERROR: Unable to create archive ${file_tar} for directory ${file}."
                  fi
                  exit 1
              fi

              file=${file_tar}
          fi

          cf_put_object ${CONTAINER} ${file} ${file_dest}
          [[ -n ${file_tar} ]] && rm -f ${file_tar}
      done
   fi
fi
