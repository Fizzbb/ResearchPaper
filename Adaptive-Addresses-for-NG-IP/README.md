# Adaptive Address for Next Generation IP protocol in Hierarical Networks
ICNP workshop : NIPAA (New IP: New Internetworking Protocols Architectures and Algorithms)

- **Abstract**

With the expected explosion in devices connected to
the Internet brought about by Internet of Things (IoT) and 5G,
IPv4 address exhaustion is unavoidable and the move to IPv6 is
considered the cure. However, the transition is not without its
challenges and some looming issues deserve investigation. First,
while the IPv6 address space satisfies the scale requirement of
Internet-addressable devices, the larger packet header caused
by 128-bit addresses has a negative impact on communication
efficiency for many envisioned applications. Second, IPv6 is a
fixed-length address scheme, which inherently lacks extensibility
and will require another overhaul if the need for larger or
independent address spaces emerge. Third, the potentially larger
forwarding tables based on longer and nested IPv6 prefixes
will challenge a router’s capacity and performance much more
than the case of IPv4. To address these issues, we propose to
use adaptive IP addresses under a strict hierarchical network
structure. The addressing scheme can be realized in a newer
generation of IP protocol (i.e., IPvn). It minimizes the communication
overhead incurred by IP addresses, enables arbitrary
address space extension, simplifies both the network data-plane
and control-plane, and supports better network security. More
importantly, it allows incremental deployment from the edge
of the network and gradual penetration into the core. A clear
boundary between IPvn domain and the existing IPv4/IPv6 networks
enables transparent cross-domain communication through
a simple header translation. The clear evolution path makes prestandard
deployment possible, allowing shorter addresses to be
used where needed so that their benefits can be fully enjoyed
instantly. In this paper we evaluate the benefit of the adaptive
address, design both control plane and data plane to support
it, and prototype the routers within and on the edge of an
IPvn domain. We open source the project to encourage further
investigation and development.

![Hierarchical network and address example. LGR stands for Level
Gateway Router; ILR stands for Intra Level Router; IPT stands for IP
Translator Router. All entity addresses are labeled in hexadecimal. Each
gateway router is labeled with a super-net prefix for the network under it.
For a prefix, before the slash is the prefix value in hexadecimal and after it
is the prefix length in decimal](/images/fig1.png)
