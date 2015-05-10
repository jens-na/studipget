studipget
=====
Get files from a Stud.IP instance.

Dependencies
=====

Installation
=====

Configuration
=====
studipget reads the file `~/.studiprc`. In this file you need to specify
your username, password and Stud.IP instance of your university.

Example:
```
instance = https://studip.hs-rm.de
user = myuser
passwd = mypassword
```

Usage
=====
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

License and Copyright
=====
Licensed under the GNU General Public License 3.

(C) Jens Nazarenus, 2015
