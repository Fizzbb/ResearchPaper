#include <core.p4>
#include <v1model.p4>

#include "header.p4"
#include "parser.p4"


control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    table debug{
        key = {
            hdr.ipv8_fix.dal: exact;
            hdr.ipv8_fix.sal: exact;
            hdr.ipv6.dstAddr: exact;
            meta.switch_subnet_len: exact;
            meta.switch_prefix_len: exact;
            meta.switch_prefix: exact;
            hdr.ethernet.etherType: exact;
            
        }
        actions = {}
    }

    apply { 
        debug.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    // multi-options to support varition addr length based on the max support
    // local variable, destination addr search key
    bit<8> addr1byte=0;
    bit<16> addr2byte=0;
    //////////common actions/////////////
    action _drop() {
        mark_to_drop(standard_metadata);
    }
    action fwd(bit<9> port) {
         standard_metadata.egress_spec = port;
    }
    ///////////ipv6///////////////
    table ipv6_lpm {
         actions = {
            _drop;
            fwd;
         }
         key = {
             hdr.ipv6.dstAddr: lpm;
         }
         size = 1024;
         default_action = _drop();
    }

    ///////////ipv8////////////////
    table ipv8_inner2_lpm {
         actions = {
            _drop;
            fwd;
         }
         key = {
             hdr.dst2.addr: lpm;
         }
         size = 1024;
         default_action = _drop();
    }
    table ipv8_inner4_lpm {
         actions = {
            _drop;
            fwd;
         }
         key = {
             hdr.dst4.addr: lpm;
         }
         size = 1024;
         default_action = _drop();
    }

    action set_params(bit<8> subnet_len, bit<8> prefix_len, bit<96> prefix, bit<9> gw_port){
        meta.switch_subnet_len = subnet_len;
        meta.switch_prefix_len = prefix_len;
        meta.switch_prefix = prefix;
        meta.gw_port = gw_port;
    }
    table switch_config {
        actions = {
            set_params;
        }
        size = 1;
    }


    apply {
        switch_config.apply();
        if (hdr.ipv6.isValid()) {
            if (hdr.ipv6.ttl == 1) {
               _drop();
            }
            else{
                hdr.ipv6.ttl = hdr.ipv6.ttl - 1;
            }
            //support one prefix_len = 12 only for now
            //by default the subnet_len + prefix_len should be equal to 16 bytes, otherwise should not be IPT-v6
            if ((meta.switch_subnet_len + meta.switch_prefix_len) == 16 && meta.switch_prefix_len == 12 && hdr.ipv6.dstAddr[127:32] == meta.switch_prefix[95:0]){
                //convert header
                hdr.ethernet.etherType = 0x888;
                hdr.ipv8_fix.setValid();
                hdr.ipv8_fix.ver = 8;
                hdr.ipv8_fix.ttl = hdr.ipv6.ttl;
                hdr.ipv8_fix.pld_len = hdr.ipv6.payloadLen;
                hdr.ipv8_fix.sal = 16;
                hdr.ipv8_fix.dal = meta.switch_subnet_len; // known is 4
                hdr.src16.setValid();
                hdr.src16.addr = hdr.ipv6.srcAddr;
                hdr.dst4.setValid();
                hdr.dst4.addr = hdr.ipv6.dstAddr[31:0];
                // no padding
                hdr.ipv6.setInvalid();
                //forwarding within IPvn network
                ipv8_inner4_lpm.apply();

            }
            else {
                ipv6_lpm.apply(); 
            }
        }
        else if (hdr.ipv8_fix.isValid()) {
            if (hdr.ipv8_fix.ttl == 1) {
                _drop();
            }
            else {
                hdr.ipv8_fix.ttl = hdr.ipv8_fix.ttl - 1;
                // convert to ipv6, temp only support SAL = 4
                if (hdr.ipv8_fix.dal > meta.switch_subnet_len && hdr.ipv8_fix.dal==16){  
                    hdr.ethernet.etherType = 0x86DD;
                    hdr.ipv6.setValid();
                    hdr.ipv6.version = 6;
                    hdr.ipv6.payloadLen = hdr.ipv8_fix.pld_len;
                    hdr.ipv6.nextHeader = 0x3B; //no next header
                    hdr.ipv6.ttl = hdr.ipv8_fix.ttl;
                    hdr.ipv6.srcAddr = meta.switch_prefix ++ hdr.src4.addr;
                    hdr.ipv6.dstAddr = hdr.dst16.addr; 
                    hdr.ipv8_fix.setInvalid();
                    hdr.src4.setInvalid();
                    hdr.dst16.setInvalid();
                    // no padding
                    //forwarding
                    ipv6_lpm.apply();
                }
                // foward within network
                else if (hdr.ipv8_fix.dal == meta.switch_subnet_len) {
                    if (hdr.ipv8_fix.dal == 2){
                        ipv8_inner2_lpm.apply();
                    }
                    else if (hdr.ipv8_fix.dal == 4){
                        ipv8_inner4_lpm.apply();
                    }
                    else{
                        _drop();
                    } 
                }
                else{
                    _drop();
                }
            }    
        }
      
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
