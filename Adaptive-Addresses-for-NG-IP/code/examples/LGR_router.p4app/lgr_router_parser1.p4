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
    // local variable, destination addr search key
    bit<16> addr2byte=0;
    bit<24> addr3byte=0;
    bit<32> addr4byte=0;
    bit<40> addr5byte=0; 
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
    action patch_src_addr1(){  //insert one byte at a time
        hdr.src_addr.push_front(1); //shift right 1,
        hdr.src_addr[0].setValid();
        hdr.src_addr[0].addr_byte = meta.switch_prefix[7:0];
        hdr.ipv8_fix.sal = hdr.ipv8_fix.sal + 1;
    }
    action patch_src_addr2(){  //insert one byte at a time
        hdr.src_addr.push_front(2); //shift right 2,
        hdr.src_addr[0].setValid();
        hdr.src_addr[0].addr_byte = meta.switch_prefix[15:8];
        hdr.src_addr[1].setValid();
        hdr.src_addr[1].addr_byte = meta.switch_prefix[7:0];
        hdr.ipv8_fix.sal = hdr.ipv8_fix.sal + 2;
    }
    action patch_src_addr3(){  //insert one byte at a time
        hdr.src_addr.push_front(3); //shift right 3,
        hdr.src_addr[0].setValid();
        hdr.src_addr[0].addr_byte = meta.switch_prefix[23:16];
        hdr.src_addr[1].setValid();
        hdr.src_addr[1].addr_byte = meta.switch_prefix[15:8];
        hdr.src_addr[2].setValid();
        hdr.src_addr[2].addr_byte = meta.switch_prefix[7:0];
        hdr.ipv8_fix.sal = hdr.ipv8_fix.sal + 3;
    }

    /////action cannot have conditions
    action rip_dst_addr1() {  //one byte
         hdr.ipv8_fix.dal = hdr.ipv8_fix.dal -1;
         hdr.dst_addr.pop_front(1); //remove the first element, index 0
    }
     action rip_dst_addr2() {  //one byte
         hdr.ipv8_fix.dal = hdr.ipv8_fix.dal -2;
         hdr.dst_addr.pop_front(2); //remove the first element, index 0
    }
     action rip_dst_addr3() {  //one byte
         hdr.ipv8_fix.dal = hdr.ipv8_fix.dal -3;
         hdr.dst_addr.pop_front(3); //remove the first element, index 0
    }

    action concat_addr2(){
        addr2byte = hdr.dst_addr[0].addr_byte ++ hdr.dst_addr[1].addr_byte; 
    }
    action concat_addr3(){
        addr3byte = hdr.dst_addr[0].addr_byte ++ hdr.dst_addr[1].addr_byte ++ hdr.dst_addr[2].addr_byte;
    }
    action concat_addr4(){
        addr4byte = hdr.dst_addr[0].addr_byte ++ hdr.dst_addr[1].addr_byte
                    ++ hdr.dst_addr[2].addr_byte ++ hdr.dst_addr[3].addr_byte;
    }
    action concat_addr5(){
        addr5byte = hdr.dst_addr[0].addr_byte ++ hdr.dst_addr[1].addr_byte
                    ++ hdr.dst_addr[2].addr_byte ++ hdr.dst_addr[3].addr_byte
                    ++ hdr.dst_addr[4].addr_byte;
    }
    table ipv8_outer2_lpm {
         actions = {
            _drop;
            fwd;
         }
         key = {
             addr2byte: lpm;
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
             addr4byte: lpm;
         }
         size = 1024;
         default_action = _drop();
    }
    table ipv8_outer5_lpm {
         actions = {
            _drop;
            fwd;
         }
         key = {
             addr5byte: lpm;
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
             hdr.dst_addr[0].addr_byte: lpm;
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
             addr2byte: lpm;
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
             addr4byte: lpm;
         }
         size = 1024;
         default_action = _drop();
    }

    action set_params(bit<8> subnet_len, bit<8> prefix_len, bit<96> prefix){
        meta.switch_subnet_len = subnet_len;
        meta.switch_prefix_len = prefix_len;
        meta.switch_prefix = prefix;
    }
    table switch_config_params {
        actions = {
            set_params;
        }
        size = 1;
    }

    table ipv8_to_gw {
        actions = {
            set_port;
        }
        size = 1;
    }

    apply {
        switch_config_params.apply();
        if (hdr.ipv4.isValid()) {
           if (hdr.ipv4.ttl == 1) {
                _drop();
           }
           else{
               hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
               ipv4_lpm.apply();
           }
        }
        else if (hdr.ipv8_fix.isValid()) {
            //// (0) ttl check
            if (hdr.ipv8_fix.ttl == 1) {
                _drop();
            }
            else {
                hdr.ipv8_fix.ttl = hdr.ipv8_fix.ttl - 1;
            
                //// (1) read switch config to meta data, move to common place
 
                //// (2) address modifiction
                //// (2.1) packet out subnet, patch switch prefix
                if ((hdr.ipv8_fix.sal < hdr.ipv8_fix.dal) && (hdr.ipv8_fix.sal < (meta.switch_subnet_len + meta.switch_prefix_len))){
                    if (meta.switch_prefix_len == 1){
                       patch_src_addr1();
                    } 
                    else if (meta.switch_prefix_len == 2){
                        patch_src_addr2();
                    }
                    else if (meta.switch_prefix_len == 3){
                        patch_src_addr3();
                    }
                    else {}  
                }
                //// (2.2) packet get in subnet or passing by, if prefix match rip switch prefix
                ////prefix_len == 0 is ILR, skip this process
                if (hdr.ipv8_fix.dal == (meta.switch_subnet_len + meta.switch_prefix_len) && (meta.switch_prefix_len!=0)){    
                    if (meta.switch_prefix_len == 1){
                        if (meta.switch_prefix[7:0] == hdr.dst_addr[0].addr_byte){
                           rip_dst_addr1();
                        }
                    }
                    else if (meta.switch_prefix_len == 2){
                        if (meta.switch_prefix[15:0] == (hdr.dst_addr[0].addr_byte ++ hdr.dst_addr[1].addr_byte)){
                            rip_dst_addr2();
                        }
                    }
                    else if (meta.switch_prefix_len == 3){
                        if (meta.switch_prefix[23:0] == (hdr.dst_addr[0].addr_byte ++ hdr.dst_addr[1].addr_byte ++ hdr.dst_addr[2].addr_byte)){
                            rip_dst_addr3();
                        }
                    }
                    else {}
                }
            
                ////(2.3) fix the padding length
                if ((hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4 == 0){ //no padding is needed
                    hdr.paddings[0].setInvalid(); 
                    hdr.paddings[1].setInvalid(); 
                    hdr.paddings[2].setInvalid(); 
                } 
                else if ((hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4 == 1) { // 3 bytes paddings are needed
                    hdr.paddings[0].setValid(); 
                    hdr.paddings[1].setValid(); 
                    hdr.paddings[2].setValid(); 
                } 
                else if ((hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4 == 2) {
                    hdr.paddings[0].setValid();
                    hdr.paddings[1].setValid();
                    hdr.paddings[2].setInvalid();
                } 
                else {
                    hdr.paddings[0].setValid();
                    hdr.paddings[1].setInvalid();
                    hdr.paddings[2].setInvalid();
                }
          
                //// (3) forwarding
                if (hdr.ipv8_fix.dal > (meta.switch_subnet_len + meta.switch_prefix_len)){  //up or supernet forward
                    ipv8_to_gw.apply();  //external, to upper level gateway 
                    if (standard_metadata.egress_spec == 0){ //use 0 indicate no uppergw available
                        _drop();
                    }             
                }
                //// search inner table first, ILR prefix len==0, no outer table
                else if (hdr.ipv8_fix.dal == meta.switch_subnet_len) { //inner net forward
                    if (meta.switch_subnet_len == 4) {
                        concat_addr4();
                        ipv8_inner4_lpm.apply();
                    }
                    else if (meta.switch_subnet_len == 2) {
                        concat_addr2();
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
                        concat_addr2();
                        ipv8_outer2_lpm.apply();
                    }
                    else if (hdr.ipv8_fix.dal == 4) {
                        concat_addr4();
                        ipv8_outer4_lpm.apply();
                    }
                    else if (hdr.ipv8_fix.dal == 5) {
                        concat_addr5();
                        ipv8_outer5_lpm.apply();
                    }
                    else {} //only support outer addr len is 4 or 5 for now
                }
                else{  //drop other conditions: 1)shorter than subnet len, 2)within internal and external
                    _drop();
                }
            }    
        }
      
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
