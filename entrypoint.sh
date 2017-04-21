#!/bin/bash
set -x

test $NTW && NTWVIP=$NTW
if [ ! $NTWVIP ]
then
  ansible all -i 'ntw01, ' -u root -m ping && export NTW=ntw01
  test $NTW || export NTW=ctl01
  export NTWVIP=`cat /etc/hosts | grep 'ntw '| awk '{print $1}'`
  test $NTWVIP || export NTWVIP=`cat /etc/hosts | grep 'ctl01'| awk '{print $1}'`
fi

ansible all -i "ctl01, " -u root -m command -a 'cat ~/keystonercv3' | grep export > keystonerc
source keystonerc

ansible all -i "$NTW, " -u root -m command -a \
	"python /usr/share/contrail-utils/provision_mx.py \
		--router_name vsrx1 \
		--router_ip $ROUTER_IP \
		--router_asn 64512 \
		--api_server_ip $NTWVIP \
		--api_server_port 8082 \
		--oper add \
		--admin_user $OS_PASSWORD \
		--admin_password $OS_PASSWORD \
		--admin_tenant_name $OS_TENANT_NAME"


openstack network create admin_internal
openstack subnet create \
	--network admin_internal \
	--gateway 192.168.113.1 \
	--dhcp \
	--subnet-range 192.168.113.0/24 \
	internal_subnet

openstack network create --share --external admin_floating
openstack subnet create --network admin_floating --dhcp --subnet-range $EXT_NET floating_subnet

openstack router create AdminRouter
openstack router set --external-gateway admin_floating AdminRouter
openstack router add subnet AdminRouter internal_subnet

ansible all -i "$NTW, " -u root -m command -a \
	"python /usr/share/contrail-utils/add_route_target.py \
		--routing_instance_name default-domain:$OS_TENANT_NAME:admin_floating:floating_subnet \
		--route_target_number 10000 \
		--router_asn 64512 \
		--admin_user $OS_USERNAME \
		--admin_password $OS_PASSWORD \
		--admin_tenant_name $OS_TENANT_NAME \
		--api_server_ip $NTW \
		--api_server_port 8082"


openstack flavor create --vcpus 1 --disk 10 --ram 2048 --property  hw:mem_page_size=large  dpdk.hpgs
