# Brostash

Linux distribution based on Debian and focusing on network security events collection. It comes with the following extra packages/tools:

* [Zeek(Bro) IDS](https://www.zeek.org/) (version: 2.6.1): compiled with PF_RING support.

* [PF_RING](http://www.ntop.org/products/packet-capture/pf_ring/) (version: 7.2.0): to speed up the packet processing.

* [Filebeat](https://www.elastic.co/products/beats/filebeat) (version: 6.6): for log shipping.

* [Packetbeat](https://www.elastic.co/products/beats/packetbeat) (version: 6.6): for network data shipping. Lightweight optional replacement of Bro.

To deploy brostash on a rasberry pi or build an elastic cluster to store the generated logs, check the ansible playbooks in [brostash-devops](https://github.com/binorassocies/brostash-devops). Also the repository [brostash-pipeline](https://github.com/binorassocies/brostash-pipeline) provides a collection of Logstash filters for different types of Bro logs.
