rackspace-cloudfiles.sh
=======================

rackspace-cloudfiles.sh is a bash script that provides command-line 
interface to Rackspace Cloud Files and includes multi-region support.  


REQUIREMENTS
------------

* Bash >= 3.0
* curl 


USAGE
-----

    rackspace-cloudfiles.sh [options] [FILE] ...

    Command-line interface to Rackspace Cloud Files for API v1.1

    -u USERNAME   username
    -k API_KEY    API key
    -a AUTH_URL   authentication URL
    -s            use ServiceNet
    -r            region (ORD, DRW)
    -c CONTAINER  Cloud Files container
    -x REQUEST    request (PUT)
    -q            quiet mode


EXAMPLES
--------

Creating a new container

    rackspace-cloudfiles.sh -u USERNAME -k API_KEY -r ORD -x PUT -c NEW_CONTAINER

Uploading file into a container

    rackspace-cloudfiles.sh -u USERNAME -k API_KEY -r ORD -x PUT -c CONTAINER /path/to/file


CREDITS
-------

This script was inspired by script written by Chmouel Boudjnah &lt;chmouel at 
chmouel dot com&gt; for API v1.0 available at [gist.github.com/chmouel/431975](http://gist.github.com/chmouel/431975)
and described in [Upload to Rackspace Cloud Files in a shell script](http://blog.chmouel.com/2010/06/09/upload-to-rackspace-cloud-files-in-a-shell-script/) article. 


LICENSE
-------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see http://www.gnu.org/licenses/.
