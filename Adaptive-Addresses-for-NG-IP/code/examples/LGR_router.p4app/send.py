from __future__ import print_function
import argparse
import sys
import random

from scapy.all import sendp, send, get_if_list, get_if_hwaddr, bind_layers
from scapy.all import Ether, IP, UDP, Raw, hexdump
import time
from newIP import IPV4, IPV8

def generator(sal=1, dal=1, sa=0x10, da=0x50, msg='hello', ipVer=8):
    """generate the IP part and payload"""
    if ipVer == 8:
    	if sal == 1 and dal == 1:
            pkt = IPV8(sal=sal, dal=dal, sa1=sa, da1=da)
    	elif sal == 2 and dal == 2:
            pkt = IPV8(sal=sal, dal=dal, sa2=sa, da2=da)
    	elif sal == 1 and dal == 2:
            pkt = IPV8(sal=sal, dal=dal, sa1=sa, da2=da)
    	elif sal == 1 and dal == 4:
            pkt = IPV8(sal=sal, dal=dal, sa1=sa, da4=da)
    	elif sal == 2 and dal == 4:
            pkt = IPV8(sal=sal, dal=dal, sa2=sa, da4=da)
    	elif sal == 4 and dal == 4:
            pkt = IPV8(sal=sal, dal=dal, sa4=sa, da4=da)       
    else:
    	pkt = IPV4(srcAddr=sa, dstAddr=da) 

    pkt = pkt / Raw(load=msg)
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
    pkt = Ether(src=get_if_hwaddr(iface), dst='ff:ff:ff:ff:ff:ff', type=0x888)

    pkt = pkt / pkt_ip
    pkt.show()

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
    msg = 'default IPV8 payload Yo!'
    cnt = 1000
    sal, dal = 2, 2
    sa, da = 0x0001, 0x0002
    ipVer = 8
    
    if len(sys.argv) > 1:
        cnt = int(sys.argv[1])
    if len(sys.argv) > 2:
        addr_len = int(sys.argv[2])
        if addr_len == 22:
            pass
        elif addr_len == 44:
            sal, dal = 4, 4
            sa, da = 0xbbbb0001, 0xaaaa0002
        elif addr_len == 24:
            sal = 2
            dal = 4
            sa, da = 0x0001, 0xbbbb0001
        else:
            print("input wrong, abort")
            exit(1)

    msg = 'default IPV{} payload Yo!'.format(ipVer)
    # define layers, so pkt.show can display new layers, not RAW load
    bind_layers(Ether, IPV8, type=0x888)
    # generate the IP layer
    pkt = generator(sal=sal, dal=dal, sa=sa, da=da, msg=msg, ipVer=ipVer)
    send_packet(pkt, cnt, ipVer)


