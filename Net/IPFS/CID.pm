package Net::IPFS::CID;
use strict;
require multibase;

our %ipldmap=qw(
	85	raw
	112	dag-pb
);

sub decode($)
{ my $cid = shift;
  my $binary = multibase::decode($cid);
  my @bytes = unpack("C*", $binary);
  $cid={};
  if($bytes[0] > 10) {
    $cid->{version} = 0;
    $cid->{ipldtype} = 112;
    $cid->{ipldtypename} = "dag-pb";
    $cid->{hash} = substr($binary, 2);
  } else {
    $cid->{version} = shift @bytes;
    $cid->{ipldtype} = shift @bytes; # asumes single-byte int < 0x80
    $cid->{ipldtypename} = $ipldmap{$cid->{ipldtype}} || die "unsupported ipld type";
    $cid->{hash} = substr($binary, 4);
  }
  $cid->{hashtype} = shift @bytes;
  $cid->{hashlen} = shift @bytes;
  return $cid;
}

sub encode($;$)
{ my $cid = shift;
  my $base = shift || "base32";
  my $head = "";
  if($cid->{version} == 1) { $head = chr($cid->{version}).chr($cid->{ipldtype}) }
  $head .= chr($cid->{hashtype}).chr($cid->{hashlen});
  return multibase::encode($base, $head.$cid->{hash});
}

1;
