==============================
`vimfind`
==============================

This is a script to enable you to easily edit your files in a directory without going into the nest subdirectories.

vf stands for vimfind.
``
$ gem install colorize
``

First, you have to locate your vf script under the bin directory

``
$ cp vf /usr/local/bin/
``

then Go to the directory you are working:

``
$ vf [keyword]
``

the following command allows you to grep and edit matching files:

``
$ vf -g [keyword]
``


