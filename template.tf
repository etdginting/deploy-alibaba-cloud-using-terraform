# ---------------
# Scaling group & configuration
# ---------------
resource "alicloud_ess_scaling_group" "scaling-group-1" {
  min_size           = 1
  max_size           = 1
  scaling_group_name = "scaling-group-1"
  default_cooldown   = 60
  vswitch_ids        = [alicloud_vswitch.zone1.id, alicloud_vswitch.zone2.id]
  removal_policies   = ["OldestScalingConfiguration", "OldestInstance"]
  multi_az_policy    = "BALANCE"
}

resource "alicloud_ess_scaling_configuration" "scaling-config-1" {
  scaling_group_id           = alicloud_ess_scaling_group.scaling-group-1.id
  image_id                   = data.alicloud_images.ubuntu-18-04-images.images[0].id
  instance_type              = "ecs.t5-lc1m1.small"
  instance_name              = "scaled-instance"
  security_group_id          = alicloud_security_group.security-group-1.id
  scaling_configuration_name = "scaling-config-1"
  internet_charge_type       = "PayByTraffic"
  internet_max_bandwidth_in  = 1
  internet_max_bandwidth_out = 1
  system_disk_category       = "cloud_efficiency"
  system_disk_size           = 20
  enable                     = true
  active                     = true
  user_data                  = data.template_file.user_data.rendered
  force_delete               = true
  
    force_delete               = true


  lifecycle {
    ignore_changes = [user_data]
  }
}

# ---------------
# Scaling rules & alarms
# ---------------
resource "alicloud_ess_scaling_rule" "add-instance" {
  scaling_group_id = alicloud_ess_scaling_group.scaling-group-1.id
  adjustment_type  = "QuantityChangeInCapacity"
  adjustment_value = 1
}

resource "alicloud_ess_scaling_rule" "remove-instance" {
  scaling_group_id = alicloud_ess_scaling_group.scaling-group-1.id
  adjustment_type  = "QuantityChangeInCapacity"
  adjustment_value = -1
}

resource "alicloud_ess_alarm" "alarm-1-add-instance" {
  name                = "alarm-1-add-instance"
  description         = "Add 1 instance when CPU usage >70%"
  alarm_actions       = [alicloud_ess_scaling_rule.add-instance.ari]
  scaling_group_id    = alicloud_ess_scaling_group.scaling-group-1.id
  metric_type         = "system"
  metric_name         = "CpuUtilization"
  period              = 60
  statistics          = "Average"
  threshold           = 70
  comparison_operator = ">="
  evaluation_count    = 2
}

resource "alicloud_ess_alarm" "alarm-2-remove-instance" {
  name                = "alarm-2-remove-instance"
  description         = "Remove 1 instance when CPU usage <10%"
  alarm_actions       = [alicloud_ess_scaling_rule.remove-instance.ari]
  scaling_group_id    = alicloud_ess_scaling_group.scaling-group-1.id
  metric_type         = "system"
  metric_name         = "CpuUtilization"
  period              = 60
  statistics          = "Average"
  threshold           = 10
  comparison_operator = "<="
  evaluation_count    = 2
}

# ---------------
# Queries & outputs
# ---------------
data "template_file" "user_data" {
  template = file("${path.module}/user-data.conf")
}

data "alicloud_images" "ubuntu-18-04-images" {
  owners      = "system"
  name_regex  = "^ubuntu_18_04"
  most_recent = true
}

data "alicloud_instances" "scaled-instances" {
  name_regex = "scaled-instance"
}

output "instances" {
  value = [data.alicloud_instances.scaled-instances.instances]
}
