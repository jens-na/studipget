#!/usr/bin/env perl
# stduipget, a tool to get files from a Stud.IP instance.
# 
# Copyright (C) 2015, Jens Nazarenus <me at jens-na dot de>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use WWW::Mechanize;
use HTML::TreeBuilder;
use Getopt::Std;
use feature qw(say);

usage() if !defined($ARGV[0]);
my %options=();
getopts("hlc:f:", \%options);
usage() if defined $options{h};

my ($user, $pass, $instance) = load_cfg();
my $folder = ".";
my $url = "$instance/index.php?again=yes";
my $client = WWW::Mechanize->new(autocheck => 1);
my $root = HTML::TreeBuilder->new;

if(!defined($instance) || length($instance) == 0) {
  print("Error: Stud.IP instance not specifed. Specify instance with " . 
    "\'instance = <...>\' in ~/.studiprc.\n");
  exit(1);
}

if(!defined($user) || !defined($pass) || length($user) == 0 
    || length($pass) == 0) {
  print("Error: user and/or password not specified. Specify \'user = " . 
    "<...>\' or \'passwd = <...>\' in ~/.studiprc.\n");
  exit(1);
}

if(has_login()) {
  if(defined($options{c}) && defined($options{l})) { list_files_by_id($options{c}); }
  elsif(defined($options{l})) { list_courses(); }
  elsif(defined($options{c} && defined($options{f}))) { dl_file_by_id($options{c}, $options{f}); }
} else {
  say("Login not successful.");
}

# Prints a list of registered courses and give them integers as
# Ids.
#
# Parameters:
# None
#
# Returns:
# Nothing
sub list_courses {
  my $courses = get_courses();
  my $counter = 1;
  foreach my $key (sort keys %$courses) {
    print($counter . " - " . %$courses{$key} . "\n");
    $counter++;
  }
}

# Prints a list of files for a specified course and give each file
# a human readable Id.
# 
# Parameters:
# id - the course_id as printed by list_courses()
#
# Returns:
# Nothing
sub list_files_by_id {
  my ($id) = @_;
  my $courses = get_courses();
  my $counter = 1;
  my $filecounter = 1;
  foreach my $key (sort keys %$courses) {
    if($counter == $id) {
      my $files = get_files($key);
      foreach my $name (sort keys %$files) {
        print("$filecounter - $name" . "\n");
        $filecounter++;
      }
      return;
    }
    else {
      $counter++;
    }
  }
}

# Returns a hash of files for a specified course.
#
# Parameters:
# id - the id of the course
#
# Returns:
# Keys: file names (a human readable file name)
# Values: an URI where the file can be found on the server.
sub get_files {
  my ($id) = @_;
  my $response = $client->get("$instance/folder.php?cid=$id");
  my $tree = $root->parse($response->content);
  my $files;
  foreach my $e ($tree->look_down(_tag => 'a')) {
    my $class = $e->attr("class");
    
    if(defined($class) && $class eq "extern") {
      my $href = $e->attr("href");
      my $name = $href =~ s/.*file_name=//r;
      $files->{ $name } = $href;
    }
  }
  return $files;
}

# Download a file by its human readable integer Ids.
# Parameters:
# course_id - human readable course Id
# file_id - human readable course Id
#
# Returns:
# Nothing
sub dl_file_by_id {
  my ($course_id, $file_id) = @_;
  my $courses = get_courses();
  my $counter = 1;
  my $filecounter = 1;
  foreach my $key (sort keys %$courses) {
    if($counter == $course_id) {
      my $files = get_files($key);
      foreach my $name (sort keys %$files) {
        if($filecounter == $file_id) {
          my $url = %$files { $name };
          dl($name, $url);
          return; 
        }
        $filecounter++;
      }
    }
    else {
      $counter++;
    }
  }
}

# Download a specific file and save it on disk.
# 
# Parameters:
# url - The url where the file is located on the server
# name - The human readable name for the file
#
# Returns:
#)Nothing
sub dl {
  my ($name, $url) = @_;
  print("GET " . $url . "\n");
  $client->get( $url, ':content_file' => "$folder/$name" );
}

# Try to log in and check for authentication errors.
#
# Returns:
# 1 - if the login was successful
# 0 - if the login was not successful
sub has_login {
  $client->get($url);
  my $response = $client->submit_form(
    form_number => 1,
    fields => {
      loginname => $user,
      password => $pass,
    }
  );
  my $tree = $root->parse($response->content);
  foreach my $e ($tree->look_down(_tag => 'div')) {
    my $class = $e->attr('class');
    if(defined($class) && $class eq "messagebox messagebox_error ") {
      return 0;
    }
  }
  return 1;
}

# Returns a hash of all courses listed in Stud.IP
#
# Returns:
# Keys: course id
# Valies: human readable title for the course
sub get_courses {
  my $response = $client->get("$instance/meine_seminare.php");
  my $tree = $root->parse($response->content);
  my $courses;

  foreach my $e ($tree->look_down(_tag => 'img')) {
    my $imgsrc = $e->attr('src');
    my $class  = $e->attr('class');
    if(defined($imgsrc) && $imgsrc =~ /.*pictures\/course\//) {
      my $id = $class =~ s/course-avatar-small course-//r;
      $courses->{ $id } = $e->attr("title");
    }
  }
  return $courses;
}

# Reads the file .studiprc in the home directory of the current user
# and tries to determine user, password and Stud.IP instance.
#
# Parameters:
# None
#
# Returns:
# user - the user name for the login
# password - the password for the login
# instance - the Stud.IP instance where to perform the login
sub load_cfg {
  my $user = undef;
  my $pass = undef;
  my $instance = undef;

  open(FILE_H, "$ENV{HOME}/.studiprc") || die("Can't open ~/.studiprc.\n");
  while (<FILE_H>) {
    chomp $_;
    (my $key,my $value) = split("=", $_);
    $value =~ s/^\s+|\s+$//g; # trim whitespace
    $key =~ s/^\s+|\s+$//g;

    if($key eq "instance") { 
      $instance = $value; 
      $instance =~ s/\/?$//g; # remove trailing slash if available
    }
    if($key eq "user") { $user = $value; }
    if($key eq "passwd") { $pass = $value; }
  }
  return ($user, $pass, $instance);
}

# Prints the tools usage and exit with exit code 0.
sub usage {
  say "Usage: $0 OPTIONS";
  print("Get files from a Stud.IP instance.\n\n");
  say("  -l     List courses or files depending on other options");
  say("  -c     Specify a course by its Id");
  say("  -f     Specify a file by its Id");
  say("  -h     Show this help");
  print("\nReport bugs here: http://github.com/jens-na/studipget/\n");
  exit(0);
}
