if( $^V lt v5.36.0 ) {
   print "1..0 # skip No core booleans\n";
   exit 0;
}

print "1..1\n";

use Data::Dump qw(dump);

$d = dump([1 == 0, 1 == 1]);

print "not " unless $d eq q([!!0, !!1]);
print "ok 1\n";
