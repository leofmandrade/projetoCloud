# Projeto de Computação em Nuvem - 2023.2
## Leonardo da França Moura de Andrade

### Descrição do projeto
O projeto consiste em provisionar uma arquitetura na AWS utilizando o Terraform, que englobe o uso de um Application Load Balancer (ALB), instâncias EC2 com Auto Scaling e um banco de dados RDS.


### Utilização do projeto
Para utilizar o projeto, é necessário ter o Terraform instalado na máquina. Após isso, basta clonar o repositório e executar os seguintes comandos:
```
terraform init
terraform plan -var="db_password=flamengo" -var="db_username=admin"
```
```
terraform apply -auto-approve -var="db_password=flamengo" -var="db_username=admin"
```

Para destruir a infraestrutura criada, basta executar o seguinte comando:
```
terraform destroy -auto-approve 
```

----

### Descrição dos recursos
#### VPC
A VPC é a Virtual Private Cloud, que é um serviço que permite a criação de uma rede virtual na AWS. Além disso, a VPC permite a criação de subnets, internet gateways, route tables e security groups, que são recursos que serão descritos a seguir e que são essenciais para a criação de uma arquitetura na AWS. Nesse projeto, foi criada uma VPC com o CIDR 10.0.0.0/16. 

#### Internet Gateway
O Internet Gateway é um serviço que permite a comunicação entre a VPC e a internet. Nesse projeto, foi criado um Internet Gateway e associado à VPC criada. 

#### Subnets
As subnets são redes privadas dentro da VPC. Nesse projeto, foram criadas 4 subnets, sendo 2 públicas e 2 privadas. As subnets públicas são associadas ao Internet Gateway e as privadas são associadas ao NAT Gateway. No caso desse projeto, as subnets públicas são utilizadas para a criação das instâncias EC2 e tem os IPs de 10.0.0.96/27 e 10.0.0.128/27. Já as subnets privadas são utilizadas para a criação do banco de dados RDS e tem os IPs de 10.0.1.96/27 e 10.0.1.128/27.    

#### NAT Gateway
O NAT Gateway é um serviço que permite a comunicação entre as subnets privadas e a internet. Nesse projeto, foi criado um NAT Gateway e associado à VPC criada.

#### Route Tables
As Route Tables são tabelas de roteamento que definem como o tráfego deve ser direcionado dentro da VPC. Nesse projeto, foram criadas 2 Route Tables, uma para as subnets públicas e outra para as subnets privadas.

#### Security Groups
Os Security Groups são grupos de segurança que definem as regras de entrada e saída de tráfego para os recursos da VPC. Nesse projeto, foram criados 3 Security Groups, um para as instâncias EC2, um para o banco de dados RDS e um para o Application Load Balancer.

#### RDS
O RDS é um serviço de banco de dados relacional da AWS. Nesse projeto, foi criado um banco de dados MySQL com 20GB de armazenamento e com backup automático.

#### EC2
O EC2 é um serviço de computação da AWS. Nesse projeto, foi criado um Launch Template para a criação das instâncias EC2, que são instâncias do tipo t2.micro com o sistema operacional Ubuntu 20.04. Além disso, foi criado um Auto Scaling Group para gerenciar as instâncias EC2, que possui uma política de escalonamento para aumentar e diminuir o número de instâncias de acordo com a utilização da CPU. Por fim, foi criado um Application Load Balancer para distribuir o tráfego entre as instâncias EC2.

#### Load Balancer
O Load Balancer é um serviço que distribui o tráfego entre as instâncias EC2. Nesse projeto, foi criado um Application Load Balancer para distribuir o tráfego entre as instâncias EC2.

#### Auto Scaling 
O Auto Scaling é um serviço que gerencia o número de instâncias EC2 de acordo com a utilização da CPU. Nesse projeto, foi criado um Auto Scaling Group para gerenciar as instâncias EC2, que possui uma política de escalonamento para aumentar e diminuir o número de instâncias de acordo com a utilização da CPU.

#### CloudWatch
O CloudWatch é um serviço de monitoramento da AWS. Nesse projeto, foram criados 2 alarmes no CloudWatch, um para aumentar o número de instâncias EC2 quando a utilização da CPU for maior que 70% e outro para diminuir o número de instâncias EC2 quando a utilização da CPU for menor que 10%.

----

### Diagrama da arquitetura



----

### Custos
![custo](img/custo.png)
