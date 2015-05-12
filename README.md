studipget
=====
Get files from a Stud.IP instance.

Dependencies
---
 - WWW::Mechanize [[debian](https://packages.debian.org/de/sid/libwww-mechanize-perl)] [[arch linux](https://www.archlinux.org/packages/community/any/perl-www-mechanize/)] [[cpan](http://search.cpan.org/~ether/WWW-Mechanize-1.74/lib/WWW/Mechanize.pm)]
 - HTML::TreeBuilder [[debian](https://packages.debian.org/en/jessie/libhtml-tree-perl)] [[arch linux](https://www.archlinux.org/packages/community/any/perl-html-tree/)]  [[cpan](http://search.cpan.org/~cjm/HTML-Tree-5.03/lib/HTML/TreeBuilder.pm)] 

Installation
---
Put `studipget` to your `$PATH` and make it executable.
Example:
```
# wget https://raw.githubusercontent.com/jens-na/studipget/master/studipget.pl -O /usr/local/bin/studipget;
# chmod +x /usr/local/bin/studipget
```

Configuration
---
studipget reads the file `~/.studiprc`. In this file you need to specify
your username, password and Stud.IP instance of your university.

Example:
```
instance = https://studip.hs-rm.de
user = myuser
passwd = mypassword
```

Usage
---
List all courses
```
$ studipget.pl -l
```

List all files for a specific course
```
$ studipget.pl -c 2 -l
```

Download file 4 from course 2
```
$ studipget.pl -c 2 -f 4
```

Limitations
---
studipget only works for a Stud.IP instance of version **2.3**. 

If your university is running a Stud.IP instance > 2.3 this will probably not work. Anyway, I am :+1: to add some polymorphism, so this script can also support 
other versions. Please open an issue if you like to give a hand.

License and Copyright
---
Licensed under the GNU General Public License 3.

(C) Jens Nazarenus, 2015
