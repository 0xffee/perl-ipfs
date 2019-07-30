#!/usr/bin/perl -w
# ipfsfuse.pl allows users to mount ipfs directories
# Copyright (C) 2019  Bernhard M. Wiedemann

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

# OneClickInstallUI http://i.opensu.se/devel:languages:perl/perl-Fuse
my $debug=0;

use strict;
#use POSIX;
use Fuse;
sub usage() { die "usage: $0 MNT\n";}
my $mnt=shift || usage;
our %cache;

sub diag{return unless $debug; print @_} # debug


sub my_getdir($)
{ my($f)=@_;
	$f=~s{[^/]$}{$&/}; # add trailing slash
	my $url=path2url($f);
	diag "getdir: $url\n";
	my $c="FIXMEcontent";
	my @ref;
	foreach my $line ($c=~m/<a href="([^"]+".*)/gi) {
		next unless $line=~m{^([^"]+)">[^<]+</a>.*(\d{2})-(\w{3})-(\d{4})\s+(\d{2}):(\d{2})\s+(\S+)}i;
		my($ref,$day,$mon,$year,$hour,$min,$size)=($1,$2,$3,$4,$5,$6,$7);
		my $d=($ref=~s{/$}{});
		next unless $ref=~m/^[^?\/]+$/; # filter out dynamic links and upward links
		my $path="$f$ref";
		#diag "cache: $path,$day,$mon,$year,$hour,$min,$size\n";
	   	$cache{$path}->{mtime}=0;
		$cache{$path}->{size}=$size if($size=~m/^\d+$/);
	   	$cache{$path}->{dir}=$d;
		if($d) {$cache{$path}->{size}=0}
		push(@ref,$ref);
	}
	return (".","..",@ref,0);
}

sub my_getattr($)
{ my($f)=@_;
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=(0,0);
	my $isfile;
	$cache{$f}||={};
	my $c=$cache{$f};
	$nlink=1;
	$uid=$<;
	($gid)=split / /,$(;
	$size=0;
	$rdev=0;
	$atime=time;
	$mtime=$atime;
	if($c) {
		$size=$c->{size};
		$mtime=$c->{mtime}||time;
		$isfile=1;
		$mode=0100444; # file
	   	if($c->{dir}) {
			$mode=0040555; # dir
			$isfile=0;
		}
	}
	$size||=0;
	$ctime=$mtime;
	$blksize=512;
	$blocks=int(($size+$blksize-1)/$blksize);
	diag "$dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks\n";
    return ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);
}

sub my_read($)
{ my($f, $size, $offs)=@_;
	my $endoffs=$offs+$size-1;
	my $url=path2url($f);
	diag "read: $url $f, $size, $offs\n";
	my $r = "FIXME file content"; #$ua->get($url, "Range"=>"bytes=$offs-$endoffs");
	my $c=$r->content;
	diag $r->status_line;
	if($r->code==416) {return ""}
	if(my $e=checkerror($r->code)) {return $e}
	return $c;
}

#my $response = $ua->get("http://localhost/~bernhard/");
#print $response->status_line, $response->content;
#exit 0;
Fuse::main(
	debug=>$debug,
	mountpoint=>$mnt,
	getdir=>\&my_getdir,
	getattr=>\&my_getattr,
	read=>\&my_read,
);
