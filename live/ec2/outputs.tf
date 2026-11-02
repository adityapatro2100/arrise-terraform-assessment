output "instance_ids" {
  value       = module.ec2_fleet.instance_ids
  description = "Instance name -> EC2 ID."
}

output "private_ips" {
  value       = module.ec2_fleet.private_ips
  description = "Instance name -> private IP."
}
