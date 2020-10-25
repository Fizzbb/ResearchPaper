#ifndef __HEADER_P4__
#define __HEADER_P4__ 1

#define MAX_BYTE 32
#define MAX_LEN 256
#define ADDR_BYTE_LEN 8

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}
header ipv6_t {
    bit<4>  version;
    bit<8>  tc;
    bit<20> flowTable;
    bit<16> payloadLen;
    bit<8>  nextHeader;
    bit<8>  ttl;
    bit<128> srcAddr;
    bit<128> dstAddr;
}

header ipv8_fix_t {
    bit<4>  ver;
    bit<4>  hdr_len;
    bit<8>  tos;
    bit<8>  next_hdr;
    bit<8>  ttl;
    bit<16> pld_len;
    bit<8>  sal;
    bit<8>  dal;
}


header addr1_t {
    bit<8> addr;
}
header addr2_t {
    bit<16> addr;
}
header addr3_t {
    bit<24> addr;
}
header addr4_t {
    bit<32> addr;
}
header addr8_t {
    bit<64> addr;
}
header addr16_t {
    bit<128> addr;
}

struct metadata {
    bit<ADDR_BYTE_LEN> sal;
    bit<ADDR_BYTE_LEN> dal;
    bit<8> padl;   
    bit<MAX_LEN> sa;
    bit<MAX_LEN> da;
    
    bit<ADDR_BYTE_LEN>  switch_subnet_len;
    bit<ADDR_BYTE_LEN>  switch_prefix_len;
    bit<96> switch_prefix;
    bit<9> gw_port;
}

struct headers {
    @name("ethernet")
    ethernet_t ethernet;
    @name("ipv6")
    ipv6_t ipv6;
    @name("ipv8")
    ipv8_fix_t ipv8_fix;
    
    addr1_t src1;
    addr1_t dst1;
    addr2_t src2;
    addr2_t dst2;
    addr4_t src4;
    addr4_t dst4;
    addr8_t src8;
    addr8_t dst8;
    addr16_t src16;
    addr16_t dst16;

    addr1_t pad1;
    addr2_t pad2;
    addr3_t pad3;

}

#endif // __HEADER_P4__
