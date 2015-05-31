#!/bin/bash
ceph-deploy purge localhost
ceph-deploy purgedata localhost
ceph-deploy forgetkeys

sudo rm -rf /var/local/osd.0

ceph-deploy new localhost

echo "osd pool default size = 1" >> ceph.conf
echo "osd objectstore = memstore" >> ceph.conf

ceph-deploy install localhost
ceph-deploy mon create-initial
ceph-deploy mon create localhost
ceph-deploy gatherkeys localhost

sudo mkdir /var/local/osd.0
ceph-deploy osd prepare localhost:/var/local/osd.0
ceph-deploy osd activate localhost:/var/local/osd.0

ceph-deploy admin localhost
sudo chmod +r /etc/ceph/ceph.client.admin.keyring
ceph health

ceph-deploy mds create localhost
ceph-deploy mon create localhost

ceph osd pool create test-default 8 8
ceph osd pool create test-optimized 100 100
