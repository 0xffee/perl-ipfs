package multibase;
use strict;

our %codecs=qw(
0 base2
f base16
b base32
k base36
z base58btc
m base64
);
our %prefix_alphabets=(
  0 => [ 0..1 ],
  b => [ "a".."z", 2..7 ],
  k => [ 0..9,"a".."z" ],
  z => [ grep /[^IOl]/, 1..9,"A".."Z","a".."z" ],
  m => [ "A".."Z", "a".."z", 0..9, "+", "/"],
);

#https://github.com/bmwiedemann/perl-ipfs/commit/83cb86c33eceafe50980ca0a1ed3409e8a8c2c9a#commitcomment-39496064

our %rcodecs;
for(keys(%codecs)) {$rcodecs{$codecs{$_}}=$_}

sub decodebasex($$$)
{ my($chars, $bitsperchar, $data) = @_;
    my $bits="";
    foreach my $c (split(//, $data)) {
        my $d=index(join("",@$chars), $c);
        $bits.=sprintf "%0${bitsperchar}B", $d;
    }
#    die $bits;
    $bits=~s/0*$//;
    pack("B*", $bits);
}
sub encodebasex($$$)
{ my($chars, $bitsperchar, $data) = @_;
    my $bits=unpack("B*", $data);
#    die $bits;
    my $res="";
    while($bits=~s/^.{1,$bitsperchar}//) {
        my $b=$&;
        while (length($b)<$bitsperchar) {$b.="0"} # pad ending
        my $d=oct("0b".$b);
#        print "$d = $b\n";
        $res.=$chars->[$d];
    }
#    die $res;
    return $res;
}
sub decodebase64($)
{decodebasex($prefix_alphabets{m}, 6, $_[0])}
sub encodebase64($)
{encodebasex($prefix_alphabets{m}, 6, $_[0])}
sub decodebase32($)
{decodebasex($prefix_alphabets{b}, 5, $_[0])}
sub encodebase32($)
{encodebasex($prefix_alphabets{b}, 5, $_[0])}
sub encodebase16($)
#{encodebasex("0123456789abcdef", 4, $_[0])}
{unpack("H*", $_[0])}
sub decodebase16($)
{pack("H*", $_[0])}
sub encodebase2($)
{my $res=encodebasex($prefix_alphabets{0}, 1, $_[0]);
    $res=~s/^0*//;
    return $res;
}
sub decodebase2($)
{my $in=shift; $in=("0" x ((-length($in))%8)).$in;
    return decodebasex($prefix_alphabets{0}, 1, $in)
}

sub decode($)
{ my $in=shift;
    my $t=substr($in, 0, 1, "");
    my $c=$codecs{$t};
#    die "type=$t codec=$c d=$in";
    no strict "refs";
    my $res=&{"decode$c"}($in);
    use strict "refs";
    return $res;
}
sub encode($$)
{ my ($base, $data)=@_;
    no strict "refs";
    my $res=&{"encode$base"}($data);
    use strict "refs";
    return $rcodecs{$base}.$res;
}

sub test {
        die if encodebase32("0123") ne "gaytemy";
        die if encodebase32("\x48\x49") ne "jbeq";
        my $d=decode("f1220c9d7d88e1ac3b8707209e9689fdb76e8959a1e543a07de7a08b28c11f5d5a007");
        #die encode("base16", decode("bciqmtv6yrynmhodqoie6s2e73n3orfm2dzkdub66pielfdar6xk2aby"));
        die if decode("mEiDJ19iOGsO4cHIJ6Wif23bolZoeVDoH3noIsowR9dWgBw") ne $d;
        die if decode("bciqmtv6yrynmhodqoie6s2e73n3orfm2dzkdub66pielfdar6xk2aby") ne $d;
        die if encode("base64", $d) ne "mEiDJ19iOGsO4cHIJ6Wif23bolZoeVDoH3noIsowR9dWgBw";
        die if encode("base32", $d) ne "bciqmtv6yrynmhodqoie6s2e73n3orfm2dzkdub66pielfdar6xk2aby";
        die if encode("base16", $d) ne "f1220c9d7d88e1ac3b8707209e9689fdb76e8959a1e543a07de7a08b28c11f5d5a007";
        die if encode("base2", "0") ne "0110000";
        die if decode("0110000") ne "0";
        die if encode("base2", $d) ne "010010001000001100100111010111110110001000111000011010110000111011100001110000011100100000100111101001011010001001111111011011011101101110100010010101100110100001111001010100001110100000011111011110011110100000100010110010100011000001000111110101110101011010000000000111";
}
test();
# f4849 = bjbeq
# f30313233 = bgaytemy

1;
