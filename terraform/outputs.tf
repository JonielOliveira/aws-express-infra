output "instance_id" {
  description = "ID da instância EC2 criada para o API"
  value = aws_instance.api_instance.id
}

output "instance_public_ip" {
  description = "IP público da EC2 (pode ser nulo se Elastic IP for usado)"
  value = aws_instance.api_instance.public_ip
}

output "elastic_ip" {
  description = "IP público fixo (Elastic IP) da instância"
  value       = aws_eip.api_eip[0].public_ip
}

output "route53_zone_id" {
  description = "ID da zona hospedada no Route 53"
  value       = aws_route53_zone.api_main_zone.zone_id
}

output "route53_name_servers" {
  description = "Nameservers gerados pelo Route 53 para configuração no Registro.br"
  value       = aws_route53_zone.api_main_zone.name_servers
}

output "ssh_example" {
  description = "Exemplo de comando SSH para acessar a instância"
  value = "ssh -i ~/.ssh/${var.ssh_key_name}.pem ubuntu@${var.create_eip ? aws_eip.api_eip[0].public_ip : aws_instance.api_instance.public_ip}"
}
