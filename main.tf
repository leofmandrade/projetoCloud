terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket  = "leofmandradebucket"
    key     = "leo-terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}


data "aws_availability_zones" "available" {
  state = "available"
}



#######
# VPC #
#######
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-terraform"
  }
}



###########
# Gateway #
###########
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "internet_gw-terraform"
  }
}



###########
# Subnets #
###########
resource "aws_subnet" "private_subnet_leo_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.96/27"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
}

resource "aws_subnet" "private_subnet_leo_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.128/27"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1c"
}

resource "aws_subnet" "public_subnet_leo_1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.96/27"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public_subnet_leo_2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.128/27"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
}



##########
# ROUTES #
##########
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }
}

resource "aws_route_table_association" "route_private1" {
  subnet_id      = aws_subnet.private_subnet_leo_1.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "route_private2" {
  subnet_id      = aws_subnet.private_subnet_leo_2.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "route_public1" {
  subnet_id      = aws_subnet.public_subnet_leo_1.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "route_public2" {
  subnet_id      = aws_subnet.public_subnet_leo_2.id
  route_table_id = aws_route_table.public_route.id
}



###################
# SECURITY GROUPS #
###################
resource "aws_security_group" "rds_instances" {
  name        = "rds_instances"
  description = "Security group para instancias RDS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Permite trafego MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_instancias.id]
  }

  tags = {
    Name = "rds_instances_sg"
  }
}

resource "aws_security_group" "lb_instances" {
  name        = "lb_instances"
  description = "Security group para instancias LB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description      = "Permite trafego HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Permite trafego ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Permite trafego https"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_instances_sg"
  }
}

resource "aws_security_group" "ec2_instancias" {
  name        = "ec2_instancias"
  description = "Security group para instancias EC2"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_instancias_sg"
  }
}



################
# DATABASE RDS #
################
resource "aws_db_instance" "db" {
  allocated_storage      = var.settings.database.allocated_storage
  engine                 = var.settings.database.engine
  engine_version         = var.settings.database.engine_version
  instance_class         = var.settings.database.instance_class
  storage_type           = "gp2"
  db_name                = "projeto"
  username               = "admin"
  password               = "flamengo"
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_instances.id]
  skip_final_snapshot    = var.settings.database.skip_final_snapshot
  publicly_accessible    = false
  parameter_group_name   = "default.mysql5.7"

  backup_window           = "02:00-03:00"
  backup_retention_period = 7
  maintenance_window      = "Mon:03:00-Mon:04:00"

  multi_az = true
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "new_db_subnet_group"
  description = "DB subnet group"
  subnet_ids  = [aws_subnet.private_subnet_leo_1.id, aws_subnet.private_subnet_leo_2.id]
  tags = {
    Name = "leo_db_subnet_group"
  }
}



#################
# EC2 INSTANCES #
#################
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}



################
# ELASTIC IP'S #
################
resource "aws_eip" "ip_elastic" {
  depends_on = [aws_internet_gateway.internet_gw]
  vpc        = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.ip_elastic.id
  subnet_id     = aws_subnet.public_subnet_leo_1.id
  tags = {
    Name = "nat gateway pra subnets privadas"
  }

  depends_on = [aws_internet_gateway.internet_gw]
}



#################
# LOAD BALANCER #
#################
resource "aws_lb" "lb" {
  name               = "terraform-lb-leo"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_instances.id]
  subnets            = [aws_subnet.public_subnet_leo_1.id, aws_subnet.public_subnet_leo_2.id]
  depends_on         = [aws_internet_gateway.internet_gw]

  tags = {
    Name = "terraform-lb-leo"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "terraform-lb-leo-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id

  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    path                = "/docs"
    protocol            = "HTTP"
  }

  tags = {
    Name = "terraform-lb-leo-tg"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }
}


######################
# AUTO SCALING GROUP #
######################
resource "aws_launch_template" "launch_template" {
  name_prefix   = "terraform-leo-launch-template"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  user_data = base64encode(<<-EOF
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    
    sudo apt-get update
    sudo apt-get install -y python3-pip python3-venv git

    # Criação do ambiente virtual e ativação
    python3 -m venv /home/ubuntu/myappenv
    source /home/ubuntu/myappenv/bin/activate

    # Clonagem do repositório da aplicação
    git clone https://github.com/ArthurCisotto/aplicacao_projeto_cloud.git /home/ubuntu/myapp

    # Instalação das dependências da aplicação
    pip install -r /home/ubuntu/myapp/requirements.txt

    sudo apt-get install -y uvicorn
 
    # Configuração da variável de ambiente para o banco de dados
    export DATABASE_URL="mysql+pymysql://admin:flamengo@${aws_db_instance.db.endpoint}/projeto"

    cd /home/ubuntu/myapp
    # Inicialização da aplicação
    uvicorn main:app --host 0.0.0.0 --port 80 
  EOF
  )

  network_interfaces {
    security_groups             = [aws_security_group.ec2_instancias.id]
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.public_subnet_leo_1.id
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "terraform-leo-launch-template"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name             = "terraform-leo-asg"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public_subnet_leo_1.id]
  target_group_arns   = [aws_lb_target_group.tg.arn]

  tag {
    key                 = "Name"
    value               = "terraform-leo-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu" {
  alarm_name          = "terraform-leo-alarm-cpu"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "70"
  ok_actions          = [aws_autoscaling_policy.scale_down_policy.arn]
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm_cpu_low" {
  alarm_name          = "terraform-leo-alarm-cpu-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"
  ok_actions          = [aws_autoscaling_policy.scale_up_policy.arn]
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "terraform-leo-scale-up-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "terraform-leo-scale-down-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}
