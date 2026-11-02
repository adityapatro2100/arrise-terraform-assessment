output "instance_ids" {
  description = "Map: logical instance name -> EC2 instance ID."
  value = merge(
    { for name, instance in aws_instance.standard : name => instance.id },
    { "payments-core" = aws_instance.protected.id }
  )
}

output "private_ips" {
  description = "Map: logical instance name -> private IPv4 address."
  value = merge(
    { for name, instance in aws_instance.standard : name => instance.private_ip },
    { "payments-core" = aws_instance.protected.private_ip }
  )
}
