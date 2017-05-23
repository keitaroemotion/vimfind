# vimfind / ymlook / ddff

vimfind is a tool to make your unix life better and easier.
This module is a bandwagon of terminal-based utilty.

- *vimfind* is an editor hacking tool. 
- *ddff* is almost similar to vimfind yet it mainly targets diff to the develop branch.
- *ymlook* is a yaml parser and analyzer(esp. for detecting dependency inconsistency in yaml fixture in rails)

## requirement

- vim is available on terminal
- you are fed up with current verbose access to large amount of files on terminal
- you are not Windows User aka asshole. (joke)

## vimfind

```
$ cd vimfind
$ install
$ bundle install
```

To look in the current directory for the file with keywords,

```
$ vf [keyword1] [keyword2]
```

If you add ? as prefix, it can grep through the file content.
```
$ vf ?[keyword]
```

Of course, you can combine the above two.

```
$ vf -a [file path]
```
This command can edit a new file with directory/subdirectory automatically created

## ddff

```
$ ddff [keyword]
```

then it enlists the result of `git diff --name-only develop` (and if you put in keyword, the result is gonna be filtered according to it)

the merit of this is you do not need to waste time inspecting the large amount of files yet just focusing on the files you have altered in your branch.


```
$ ddff -h
```
this can show the help menu.

### sync option

```
$ ddff sync
```
this option can allow you to pick files from another branch, which is not yet merged.

[Unstable] If you are Mac OSX user,

```
[enter number: /all ... :c] :c
```

This option might allow you to copy the result of file list to the clipboard

## ymlook

This script is mainly created for reducing the cost of looking through rails yaml fixture relation verbose. ymlook is the powerful tool to find the inconsistent part in `test/fixtures` *automatically*.

```
$ ymlook
```

For detail, please check the console output.

If you have any questions, please contact me:

tobasojyo@gmail.com


# Donation

If you are really generous guy helping me continue this project, please donate me. The way to donate is check out iTunes or Amazon and search "keita roimo" and buy one of my Albums. Thank you. Yay! 
