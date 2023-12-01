variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_cidr_block" {
  description = "CIDR para VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_count" {
  description = "Numero de subnets"
  type        = map(number)
  default = {
    public  = 2,
    private = 2
  }
}

variable "settings" {
  description = "Configuracoes"
  type        = map(any)
  default = {
    "database" = {
      "allocated_storage"   = 20
      "engine"              = "mysql"
      "engine_version"      = "5.7"
      "instance_class"      = "db.t2.micro"
      "db_name"             = "projeto"
      "skip_final_snapshot" = true
    },
    "web_app" = {
      count         = 1
      instance_type = "t2.micro"
    }
  }
}

variable "db_username" {
  description = "Usuario do banco de dados"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha do banco de dados"
  type        = string
  sensitive   = true
}