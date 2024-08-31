data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["Default VPC"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "sara-ecc-tf"   #Change

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    sara-ecs-tf = { #task def and service name -> #Change
      cpu    = 512
      memory = 1024

      # Container definition(s)
      container_definitions = {

        sara-ecs-sample = { #container name
          essential = true 
          # image     = "public.ecr.aws/docker/library/httpd:latest"
          image     = "public.ecr.aws/u2q1a2y8/sara-node-app/hello-node-app:v1" 
          port_mappings = [
            {
             # name          = "sara-ecs-sample"  #container name
             name          = "hello-node-app-ecs"  # modified from above line
              containerPort = 8080
              protocol      = "tcp"
            }
          ]
          readonly_root_filesystem = false

        }
      }
      assign_public_ip                   = true
      deployment_minimum_healthy_percent = 100
      subnet_ids                         = flatten(data.aws_subnets.public.ids)
      security_group_ids                 = [aws_security_group.allow_sg.id]
    }
  }
}

resource "aws_security_group" "allow_sg" {
  name        = "sara_allow_tls" # added my name
  description = "Allow traffic"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description = "Allow all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    #cidr_blocks = [data.aws_vpc.selected.cidr_block]
    cidr_blocks = ["0.0.0.0/0"] # added my self base previous excise
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_sg"
  }
}