SNMP-BCC -- SNMP Backdoor Communication Channel
===============================================
Written by: Anestis Bechtsoudis @ bechtsoudis.com

Copyright (C) 2012 Anestis Bechtsoudis


Disclaimer
----------

The tool is only for testing purposes and can only be used where strict consent 
has been given. Do not use it for illegal purposes.


License
-------

Any modifications, changes, or alterations to this application is acceptable, 
however, any public releases utilizing this code must be approved by its creator. 
Check the LICENSE file for more information.


Requirements
------------
 - perl installed
 - libnet-rawip-perl
 - libio-socket-socks-perl (used at PoC client backdoor)


Usage
-----

```bash
Usage: snmpbcc.pl [options]

Options:
  -c    SNMP Community String

  -t    Target Host IP:Port

  -r    SNMP Relay Service IP:PORT

  -h    Display help message
````


Backdoor PoC Client
-------------------

A tiny PoC client backdoor written in perl is included to test SNMP-BCC under various
setups. You can run the backdoor.pl at the client host to receive the commands over SNMP.
After concluding to the tool's working protocol I'll implement a generation
engine for various backdoor payloads to use at client hosts.


Examples
--------

Send commands to 10.0.11.22:4444 using 10.0.12.52:161 as relay:

`./snmpbcc.pl -c public -t 10.0.11.22:4444 -r 10.0.12.52:161`
