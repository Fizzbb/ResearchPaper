const bit<16> TYPE_IPV6 = 0x86DD;
const bit<16> TYPE_IPV8 = 0x888;


/******P A R S E R*************/

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            TYPE_IPV6: parse_ipv6;
            TYPE_IPV8: parse_ipv8; 
            default: accept;
        }
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition accept;
    }

    ///////////////IPvn parser method 2 ///////////////
    state parse_ipv8 {
        packet.extract(hdr.ipv8_fix);
        meta.padl = 4 - (hdr.ipv8_fix.sal + hdr.ipv8_fix.dal) % 4;
        transition select(hdr.ipv8_fix.sal) {
            1:parse_ipv8_src1;
            2:parse_ipv8_src2;
            4:parse_ipv8_src4;
            16:parse_ipv8_src16;
        }
    }
    state parse_ipv8_src1{
        packet.extract(hdr.src1);
        transition select(hdr.ipv8_fix.dal) {
            1:parse_ipv8_dst1;
            2:parse_ipv8_dst2;
            4:parse_ipv8_dst4;
            16:parse_ipv8_dst16;
        }
    }
    state parse_ipv8_src2{
        packet.extract(hdr.src2);
        transition select(hdr.ipv8_fix.dal) {
            1:parse_ipv8_dst1;
            2:parse_ipv8_dst2;
            4:parse_ipv8_dst4;
            16:parse_ipv8_dst16;
        }
    }
    state parse_ipv8_src4{
        packet.extract(hdr.src4);
        transition select(hdr.ipv8_fix.dal) {
            1:parse_ipv8_dst1;
            2:parse_ipv8_dst2;
            4:parse_ipv8_dst4;
            16:parse_ipv8_dst16;
        }
    }
    state parse_ipv8_src16{
        packet.extract(hdr.src16);
        transition select(hdr.ipv8_fix.dal) {
            1:parse_ipv8_dst1;
            2:parse_ipv8_dst2;
            4:parse_ipv8_dst4;
            16:parse_ipv8_dst16;
        }
    }
    state parse_ipv8_dst1{
        packet.extract(hdr.dst1);
        transition select(meta.padl) {
            1:parse_pad1;
            2:parse_pad2;
            3:parse_pad3;
            4:accept;
        }
    }
    state parse_ipv8_dst2{
        packet.extract(hdr.dst2);
        transition select(meta.padl) {
            1:parse_pad1;
            2:parse_pad2;
            3:parse_pad3;
            4:accept;
        }
    }
    state parse_ipv8_dst4{
        packet.extract(hdr.dst4);
        transition select(meta.padl) {
            1:parse_pad1;
            2:parse_pad2;
            3:parse_pad3;
            4:accept;
        }
    }
    state parse_ipv8_dst16{
        packet.extract(hdr.dst16);
        transition select(meta.padl) {
            1:parse_pad1;
            2:parse_pad2;
            3:parse_pad3;
            4:accept;
        }
    }
    state parse_pad1{
        packet.extract(hdr.pad1);
        transition accept;
    }
    state parse_pad2{
        packet.extract(hdr.pad2);
        transition accept;
    }
    state parse_pad3{
        packet.extract(hdr.pad3);
        transition accept;
    }

    /////////start state////////////
    state start {
        transition parse_ethernet;
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv6);
        packet.emit(hdr.ipv8_fix);
        //1,2,4 only one is valid
        packet.emit(hdr.src1);
        packet.emit(hdr.src2);
        packet.emit(hdr.src4);
        packet.emit(hdr.src16);
        packet.emit(hdr.dst1);
        packet.emit(hdr.dst2);
        packet.emit(hdr.dst4);
        packet.emit(hdr.dst16);
        packet.emit(hdr.pad1);
        packet.emit(hdr.pad2);
        packet.emit(hdr.pad3);

    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}
