#/usr/bin/env python
from __future__ import print_function
import sys
import struct
import os

from scapy.all import sniff, sendp, hexdump, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Ether, IP, IPv6, TCP, UDP, Raw, hexdump
import time
from newIP import IPV4, IPV8
import pickle

# define layers, so pkt.show can display new layers, not RAW load
bind_layers(Ether, IPV8, type=0x888)
bind_layers(Ether, IPv6, type=0x86DD)

def get_if():
    ifs=get_if_list()
    iface=None
    for i in get_if_list():
        if "eth0" in i:
            iface=i
            break;
    if not iface:
        print("Cannot find eth0 interface")
        exit(1)
    return iface

cnt = t1 = t2 =0
latency_list = []
ingress_list = []
egress_list = []
def handle_pkt(pkt):
    global cnt, t1
    cnt += 1

    if cnt == 1:
        t1 = time.time()
    if cnt%1000 < 10:
        pkt.show()
        hexdump(pkt)
    if cnt%1000==0:
        print("takes {} sec to receive {} pkt".format(time.time()-t1, cnt))
        #pickle.dump(latency_list, open('/tmp/latency.pkl','wb'))

 
    sys.stdout.flush()


def main():
    ifaces = list(filter(lambda i: 'eth' in i, os.listdir('/sys/class/net/')))
    iface = ifaces[0]
    print("sniffing on {}".format(iface))
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
