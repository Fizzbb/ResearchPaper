#include <core.p4>
#include <v1model.p4>

#include "header.p4"
#include "parser.p4"


control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    ///for debug, print the metadata in the log
    table debug{
        key = {
            standard_metadata.ingress_global_timestamp: exact;
            standard_metadata.egress_global_timestamp: exact;
            standard_metadata.enq_timestamp: exact;
            standard_metadata.deq_timedelta : exact;
            standard_metadata.enq_qdepth : exact;
            standard_metadata.deq_qdepth : exact;
        }
        actions = {}
    }
    apply { 
        //debug.apply();
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
    action set_port(bit<9> port) {  /// this is for upper level gateway port
        standard_metadata.egress_spec = port;
    }
    table ipv8_outer2_lpm {
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

    table ipv8_outer4_lpm {
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
            //// (0) ttl check
            if (hdr.ipv8_fix.ttl == 1) {
                _drop();
            }
            else {
                hdr.ipv8_fix.ttl = hdr.ipv8_fix.ttl - 1;
                //// (2) address modifiction
                //// (2.1) packet out subnet, patch switch prefix
                if ((hdr.ipv8_fix.sal < hdr.ipv8_fix.dal) && (hdr.ipv8_fix.sal < (meta.switch_subnet_len + meta.switch_prefix_len))){
                    //update SAL first
                    hdr.ipv8_fix.sal = meta.switch_prefix_len + hdr.ipv8_fix.sal;
                    if (meta.switch_prefix_len == 1 && meta.switch_subnet_len==1){
                        hdr.src2.setValid();
                        hdr.src2.addr = meta.switch_prefix[7:0] ++ hdr.src1.addr;
                        hdr.src1.setInvalid();
                    } 
                    else if (meta.switch_prefix_len == 2 && meta.switch_subnet_len==2){
                        
                        hdr.src4.setValid();
                        hdr.src4.addr = meta.switch_prefix[15:0] ++ hdr.src2.addr;
                        hdr.src2.setInvalid();
                    }
                    else {}  // tmp support 2 combination only 
                }
                //// (2.2) packet get in subnet or passing by, if prefix match rip switch prefix
                ////prefix_len == 0 is ILR, skip this process
                if (hdr.ipv8_fix.dal == (meta.switch_subnet_len + meta.switch_prefix_len) && (meta.switch_prefix_len!=0)){    
                    if (meta.switch_prefix_len == 1 && hdr.ipv8_fix.dal==2){
                        if (meta.switch_prefix[7:0] == hdr.dst2.addr[15:8]){
                            //rip prefix one byte
                            hdr.dst1.setValid();
                            hdr.dst1.addr = hdr.dst2.addr[7:0];
                            hdr.ipv8_fix.dal = meta.switch_subnet_len; //1
                            hdr.dst2.setInvalid();
                        }
                    }
                    else if (meta.switch_prefix_len == 2 && hdr.ipv8_fix.dal==4){
                        if (meta.switch_prefix[15:0] == hdr.dst4.addr[31:16]){
                            //rip prefix two bytes
                            hdr.dst2.setValid();
                            hdr.dst2.addr = hdr.dst4.addr[15:0];
                            hdr.ipv8_fix.dal = meta.switch_subnet_len; //2
                            hdr.dst4.setInvalid();
                        }
                    }
                    else {}
                }
                
                ////(2.3) fix the padding length
                hdr.pad1.setInvalid();
                hdr.pad2.setInvalid();
                hdr.pad3.setInvalid();
                if ((hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4 == 1) {
                    hdr.pad3.setValid();
                } 
                else if ((hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4 == 2) {
                    hdr.pad2.setValid(); 
                } 
                else if ((hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4 == 3) {
                    hdr.pad1.setValid();
                } 
          
                //// (3) forwarding
                if (hdr.ipv8_fix.dal > (meta.switch_subnet_len + meta.switch_prefix_len)){  //up or supernet forward
                    standard_metadata.egress_spec = meta.gw_port;             
                }
                //// search inner table first, ILR prefix len==0, no outer table
                else if (hdr.ipv8_fix.dal == meta.switch_subnet_len) { //inner net forward
                    if (meta.switch_subnet_len == 4) {
                        ipv8_inner4_lpm.apply();
                    }
                    else if (meta.switch_subnet_len == 2) {
                        ipv8_inner2_lpm.apply();
                    }
                    else if (meta.switch_subnet_len == 1) {
                        ipv8_inner1_lpm.apply();
                    }
                    else {} //only support inner addr len is 1,2 or 4for now
                }
                //// search outer table 
                else if (hdr.ipv8_fix.dal == (meta.switch_subnet_len + meta.switch_prefix_len)){ 
                    if (hdr.ipv8_fix.dal == 2) {
                        ipv8_outer2_lpm.apply();
                    }
                    else if (hdr.ipv8_fix.dal == 4) {
                        ipv8_outer4_lpm.apply();
                    }
                    else {} //only support outer addr len is 4 or 2 for now
                }
                else{  //drop other conditions: 1)shorter than subnet len, 2)within internal and external
                    _drop();
                }
            }    
        }
      
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
