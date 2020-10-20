#include <core.p4>
#include <v1model.p4>

#include "header.p4"
#include "parser.p4"


control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    table debug{
        key = {
            hdr.ipv8_fix.dal: exact;
            hdr.ipv8_fix.sal: exact;
            meta.switch_subnet_len: exact;
            meta.switch_prefix_len: exact;
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
    //////////common actions/////////////
    action _drop() {
        mark_to_drop(standard_metadata);
    }
    action fwd(bit<9> port) {
         standard_metadata.egress_spec = port;
    }
    ///////////ipv8////////////////
    table ipv8_inner1_lpm {
         actions = {
            _drop;
            fwd;
         }
         key = {
             hdr.dst1.addr: lpm;
         }
         size = 1024;
         default_action = _drop();
    }
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

        if (hdr.ipv8_fix.isValid()) {
            if (hdr.ipv8_fix.ttl == 1) {
                _drop();
            }
            else {
                hdr.ipv8_fix.ttl = hdr.ipv8_fix.ttl - 1;
                if (hdr.ipv8_fix.dal > meta.switch_subnet_len){  //up or supernet forward
                    standard_metadata.egress_spec = meta.gw_port; 
                }
                else if (hdr.ipv8_fix.dal == meta.switch_subnet_len) { //inner net forward
                    if (hdr.ipv8_fix.dal == 1){
                        ipv8_inner1_lpm.apply();
                    }
                    else if (hdr.ipv8_fix.dal == 2){
                        ipv8_inner2_lpm.apply();
                    }
                    else if (hdr.ipv8_fix.dal == 4){
                        ipv8_inner4_lpm.apply();
                    }
                    else {_drop();}
                }
                else{
                    _drop();
                }
            }    
        }
      
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
