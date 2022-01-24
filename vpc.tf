#--------------
# VPC & VSwitches
#--------------
data "alicloud_zones" "default" {
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "vpc" {
  name       = "vpc"
  cidr_block = "192.168.0.0/24"
}

resource "alicloud_vswitch" "zone-1a" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "192.168.200.0/25"
  availability_zone = data.alicloud_zones.default.zones[0].id
  name              = "zone-1a"
}

resource "alicloud_vswitch" "zone-1b" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "192.168.300.0/25"
  availability_zone = data.alicloud_zones.default.zones[1].id
  name              = "zone-1b"
}

#--------------
# Security groups
#--------------
resource "alicloud_security_group" "security-group-1" {
  name        = "security-group-1"
  description = "security-group-1"
  vpc_id      = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "security-group-1-http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.security-group-1.id
  cidr_ip           = "0.0.0.0/0"
}
