# $Id$
BEGIN { $| = 1; print "1..1\n"; }
END   {print "not ok\n" unless $loaded;}

# Test it loads
use Mac::PropertyList;
$loaded = 1;
print "ok\n";
