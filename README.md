#Brostash = Bro IDS + Logstash

Linux distribution based on Debian and focusing on network security events collection. It comes with the following extra packages/tools:

* [Bro IDS](https://www.bro.org/) (version: 2.4.1): compiled to with PF_RING support.
* [Logstash](https://www.elastic.co/products/logstash) (version: 2.2): for logs shipping.
* [PF_RING](http://www.ntop.org/products/packet-capture/pf_ring/) (version: 6.2.0): to speed up the packet processing.
* [Criticalstack](https://www.criticalstack.com/): for open source intel feeds integration with the bro intel module.
* Extra tools: [munin](http://munin-monitoring.org/) (system monitoring), nmap...

Brostash offers also a build script for the raspbian lite image. All the tools listed above, except PF_RING, are included in this image.
