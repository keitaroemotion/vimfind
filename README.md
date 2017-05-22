# vimfind/ymlook/ddff

vimfind is a tool to make your unix life easier.
This module is a bandwagon of terminal-based utilty.

- *vimfind* as editor hacking tool. 
- *ymlook* as yaml parser and analyzer(esp. for detecting dependency inconsistency in yaml fixture in rails)
- *ddff* is almost similar to vimfind yet it mainly targets diff to the develop branch.

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
$vf ?[keyword]
```

Of course, you can combine the above two.


