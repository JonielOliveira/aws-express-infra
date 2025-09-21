variable "aws_region" {
  description = "Região da AWS onde os recursos serão provisionados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome ou prefixo usado para identificar e taguear os recursos do projeto."
  type        = string
  default     = "aws-express-infra"
}

variable "environment_name" {
  description = "Nome do ambiente onde os recursos estão sendo provisionados (ex: dev, staging, production)."
  type        = string
  default     = "universal"
}

variable "owner_name" {
  description = "Nome do proprietário dos recursos"
  type        = string
  default     = "usuário"
}

variable "ami_id" {
  description = "ID da Amazon Machine Image (AMI) a ser utilizada para a instância EC2"
  type        = string
  default     = "ami-034568121cfdea9c3" # Ubuntu Server (Noble Numbat) 24.04 LTS (na região us-east-1)
}

variable "instance_type" {
  description = "Tipo da instância EC2 (ex: t3.micro, t3.small, etc)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_key_name" {
  description = "Nome da chave SSH criada na AWS EC2"
  type        = string
}

variable "ssh_ingress_cidr" {
  description = "Faixa de IP (CIDR) autorizada a acessar a instância via SSH (ex: seu_ip/32)."
  type        = string
  default     = "0.0.0.0/0"
}

variable "hosted_zone_id" {
  description = "ID da Hosted Zone no Route53 onde o domínio está configurado."
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Domínio que será usado para a aplicação"
  type        = string
}

variable "create_eip" {
  description = "Se verdadeiro, aloca e associa um Elastic IP à instância."
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Se verdadeiro, associa a função IAM com permissão para usar o AWS Systems Manager (SSM)."
  type        = bool
  default     = true
}
