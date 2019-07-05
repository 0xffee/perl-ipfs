#!/usr/bin/perl -w
use strict;
use Google::ProtocolBuffers;
use Data::Dumper;
BEGIN{my $dir=$0; $dir=~s!/[^/]*$!!; $dir||=".";
push @INC, $dir;
}
require DataPb;
require multibase;

# from /home/bernhard/go/pkg/mod/github.com/ipfs/go-unixfs@v0.0.5/pb/unixfs.proto
# /home/bernhard/go/pkg/mod/github.com/ipfs/go-merkledag@v0.0.3/pb/merkledag.proto
Google::ProtocolBuffers->parse("
message PBLink {

  // multihash of the target object
  optional bytes Hash = 1;

  // utf string name. should be unique per object
  optional string Name = 2;

  // cumulative size of target object
  optional uint64 Tsize = 3;
}

// An IPFS MerkleDAG Node
message PBNode {

  // refs to other objects
  repeated PBLink Links = 2;

  // opaque user data
  optional bytes Data = 1;
}
",
               {create_accessors => 1 }
);

# ipfs object get BCIQMTV6YRYNMHODQOIE6S2E73N3ORFM2DZKDUB66PIELFDAR6XK2ABY # for comparison
# {"Links":[{"Name":"history","Hash":"QmQ2iLtk6rNrzocgZvdhYAeBLaA5zNikdbfHG57dbiggK5","Size":5368640909438},{"Name":"tumbleweed","Hash":"QmQyjGFoj2L7UvJWCBJ4hkCmk9HQicdms8pNbqL7mNFudY","Size":94350582209}],"Data":"\u0008\u0001"}
# http://localhost:5001/ipfs/QmSDgpiHco5yXdyVTfhKxr3aiJ82ynz8V14QcGKicM3rVh/#/explore/QmbvZYyDrgEBvBEiucpoyUqhbTa6gy9aPBfxcYLT16esDp
# Links ; Data
my $d=`cat $ENV{HOME}/.ipfs/blocks/AB/CIQMTV6YRYNMHODQOIE6S2E73N3ORFM2DZKDUB66PIELFDAR6XK2ABY.data`;

$d = PBNode->decode($d);
#print Dumper $d;
print "CID: ".multibase::encode("base16",$d->Links->[0]->Hash)."\n";
print(Dumper(Unixfs::Pb::Data->decode($d->Data)));
print("data type=", Unixfs::Pb::Data->decode($d->Data)->{Type}, "\n");
