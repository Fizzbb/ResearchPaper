from __future__ import print_function
import argparse
import sys
import random

from scapy.all import sendp, send, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Ether, IP, IPv6, UDP, Raw, hexdump
import time
from newIP import IPV4, IPV8

def generator(sal=1, dal=1, sa=0x10, da=0x50, ipVer=8, plen=24):
    """generate the IP part and payload"""
    if ipVer == 8:
    	if sal == 1 and dal == 1:
            pkt = IPV8(sal=sal, dal=dal, sa1=sa, da1=da, plen=plen)
    	elif sal == 2 and dal == 2:
            pkt = IPV8(sal=sal, dal=dal, sa2=sa, da2=da, plen=plen)
    	elif sal == 1 and dal == 2:
            pkt = IPV8(sal=sal, dal=dal, sa1=sa, da2=da, plen=plen)
    	elif sal == 1 and dal == 4:
            pkt = IPV8(sal=sal, dal=dal, sa1=sa, da4=da, plen=plen)
    	elif sal == 2 and dal == 4:
            pkt = IPV8(sal=sal, dal=dal, sa2=sa, da4=da, plen=plen)
    	elif sal == 4 and dal == 4:
            pkt = IPV8(sal=sal, dal=dal, sa4=sa, da4=da, plen=plen)      
    	elif sal == 4 and dal == 16:
            pkt = IPV8(sal=sal, dal=dal, sa4=sa, da16=da, plen=plen)
    	else:
            print("SAL {}, DAL {} is not support yet. Abort Early".format(sal, dal))
            exit(1)
    else:
    	pkt = IPV4(srcAddr=sa, dstAddr=da) 

    return pkt


def send_packet(pkt_ip, cnt=1, ipVer=8,iface=None):
    """send packet through eth0 or 1st available interfaces"""
    if iface is None:
        ifs = get_if_list()
        for i in ifs:
            if "eth0" in i:
                iface = i
                break
        if not iface: # tmp test
            iface = 'lo'
    if ipVer==8:
    	pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x888)
    elif ipVer==6:
        pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x86DD)
    else:
        print("IP version {} is not supported. Abort Early".format(inVer))
        exit(1)

    pkt = pkt / pkt_ip
    pkt.show()
    hexdump(pkt)

    t0 = time.time()
    sendp(pkt, iface=iface, count=cnt, inter=0.001, verbose=True)
    t_span = time.time() - t0
    print("send {} IPv{} packts use {} sec".format(cnt, ipVer, t_span))
    return iface


if __name__ == '__main__':
    # packet design
    # input arguments order sal, dal, sa, da,  all are string type, first two are decimal, last two are hex
    # fifth and six argument is optional for packet cnt and payload
    # example: python packetGen.py 2 2 0x0001 0x0002

    # define layers, so pkt.show can display new layers, not RAW load
    bind_layers(Ether, IPV8, type=0x888)
    bind_layers(Ether, IPv6, type=0x86DD)
   
    cnt = 1000
    sal, dal = 4, 16
    sa, da = 0xaaaa0001, 0x200100000000000000000000aaaa0002
    ipVer = 8
    
    if len(sys.argv) > 1:
        ipVer = int(sys.argv[1])
    if len(sys.argv) > 2:
        cnt = int(sys.argv[2])
   
    msg  = 'default IPV{} payload Yo!'.format(ipVer)

    # generate the IP layer
    if ipVer == 4:
        # default ip from mininet autoconfig
        pkt=IP(src="10.0.1.101",dst="10.0.2.101")
    elif ipVer == 6:
        pkt=IPv6(src="2002::aaaa:0001",dst="2001::aaaa:0002", plen=len(msg), nh=0x3b)
    else:
        pkt = generator(sal=sal, dal=dal, sa=sa, da=da, ipVer=ipVer, plen=len(msg))
  

    msg = 'default IPV{} payload Yo!'.format(ipVer)
    # add payload and layer 2 in send function
    pkt = pkt / Raw(load=msg)
    send_packet(pkt, cnt, ipVer)


