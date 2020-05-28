#!/usr/bin/perl
use warnings;
use strict;

use bigint;

my $src = "Decentralize everything!!";

for my $prefix_alphabet (
  [ z => [ grep /[^IOl]/, 1..9,"A".."Z","a".."z" ] ],
  [ k => [ 0..9,"a".."z" ] ],
  [ m => [ "a".."z", 2..7 ] ],
  [ f => [ 0..9,"a".."f" ] ],
  [ 0 => [ 0..1 ] ],
) {
  my $enc = $prefix_alphabet->[0] . encode( $src, $prefix_alphabet->[1] );
  my $dec = decode( substr( $enc, 1 ), $prefix_alphabet->[1] );
  printf( "%s => %s => %s\n", $src, $enc, $dec )
}

sub encode {
  my( $bytes, $alphabet ) = @_ ;
  $bytes =~ /^\0*/;
  my $lead = $alphabet->[0] x $+[0];
  my $out = "";
  my $val = hex( unpack( "H*", $bytes ) );
  $out = $alphabet->[ ($val->bdiv( 0+@$alphabet ))[1] ] . $out while $val;
  return $lead . $out;
}

sub decode {
  my( $enc, $alphabet ) = @_ ;
  $enc =~ /^\Q@{[ $alphabet->[0] ]}\E*/;
  my $lead = "\x00" x $+[0];
  my $out = Math::BigInt->new;
  my $reval = {};
  $reval->{$_} = keys %$reval for @$alphabet;
  while( $enc ne "" ) { $out = ( $out * @$alphabet ) + $reval->{ substr( $enc, 0, 1, "" ) } }
  return $lead . pack( "H*", $out->as_hex );
}
