from scapy.all import Packet
from scapy.fields import *

class IPV4(Packet):
    fields_desc = [
                   # fixed length field
                   BitField("ver", 4, 4),
                   BitField("ihl", 0, 4),
                   BitField("diffserv", 0, 8),
                   BitField("totalLen", 0, 16),
                   BitField("identification", 1, 16),
                   BitField("flags", 0, 3),
                   BitField("fragOffset", 0, 13),
                   BitField("ttl", 30, 8),
                   BitField("protocol", 0, 8),
                   BitField("hdrChecksum", 0, 16),
                   XBitField("srcAddr", 0x01, 32),
                   XBitField("dstAddr", 0x02, 32)
                  ]

class IPV6(Packet):
    fields_desc = [
                   # fixed length field
                   BitField("ver", 6, 4),
                   BitField("tc", 0, 8),
                   BitField("flowTable", 0, 20),
                   BitField("payloadLen", 0, 16),
                   BitField("nextheader", 0, 8),
                   BitField("ttl", 30, 8),
                   XBitField("srcAddr", 0x01, 128),
                   XBitField("dstAddr", 0x02, 128)
                  ]


class IPV8(Packet):
    fields_desc = [
                   # fixed length field
                   BitField("ver", 8, 4),
                   BitField("hdr_len", 10, 4),
                   BitField("tos", 0, 8),
                   BitField("next_hdr", 0, 8),
                   BitField("ttl", 30, 8),
                   BitField("payload_len", 16, 16),
                   BitField("sal", 3, 8),    # default byte len is 1, 8bit variable
                   BitField("dal", 4, 8),
                   # variable length field, implemented with ConditionField, XBitField for hex display
                   ConditionalField(XBitField("sa1", 0x11, 8), lambda pkt: pkt.sal == 1),
                   ConditionalField(XBitField("sa2", 0x1122, 16), lambda pkt: pkt.sal == 2),
                   ConditionalField(XBitField("sa3", 0x112233, 24), lambda pkt: pkt.sal == 3),
                   ConditionalField(XBitField("sa4", 0x11223344, 32), lambda pkt: pkt.sal == 4),

                   ConditionalField(XBitField("da1", 0x11, 8), lambda pkt: pkt.dal == 1),
                   ConditionalField(XBitField("da2", 0x1122, 16), lambda pkt: pkt.dal == 2),
                   ConditionalField(XBitField("da3", 0x112233, 24), lambda pkt: pkt.dal == 3),
                   ConditionalField(XBitField("da4", 0x11223344, 32), lambda pkt: pkt.dal == 4),

                   ConditionalField(XBitField("pad1", 0x0, 8), lambda pkt: (pkt.sal + pkt.dal) % 4 == 3),
                   ConditionalField(XBitField("pad2", 0x0, 16), lambda pkt: (pkt.sal + pkt.dal) % 4 == 2),
                   ConditionalField(XBitField("pad3", 0x0, 24), lambda pkt: (pkt.sal + pkt.dal) % 4 == 1)
                  ]



