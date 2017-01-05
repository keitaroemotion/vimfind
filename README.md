==============================
vimfind
==============================

This is a script to enable you to easily edit your files in a directory without going into the nest subdirectories.

vf stands for vimfind.

`
$ gem install colorize
`

First, you have to locate your vf script under the bin directory

`
$ cp vf /usr/local/bin/
`

then Go to the directory you are working:

`
$ vf [keyword]
`

the following command allows you to grep and edit matching files:

`
$ vf w:[keyword]
`

================
For Rails Users
================

If you are ruby user, you can find/grep through the [model/view/controller]

List Files:

`
$ vf -mvc [@name] 
`

List Files Contains the keyword

`
$ vf -mvc [@name] w:[keyword]
`

You encounter with the following suggestion while searching:

`
app/models/sample.rb ? [y/q/w/p/l/d/t]
`

v ... Open the current file.

q ... Quit Application

w ... Show the lines matching your w:[keyword] query

p ... Go to Previous Selection. 

l ... List the Functions of the Current File.

d ... Can easily access to your db schema.

t ... Run Unit Test for the selected file

You can access to the db schema by entering "d", and
when you enter any keyword, the result would come up
with highlighted results

===============
Wiki Features
===============

vf supports local wiki management features.

enlist the current articles
`
vf :wi
`

add article
`
vf :wi [term]
`

open urls in an article

`
vf :wio term
`

