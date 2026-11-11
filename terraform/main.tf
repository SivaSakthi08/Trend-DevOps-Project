
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# 1. Trendify VPC
resource "aws_vpc" "trend_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "trendify-vpc"
    Project = "Trendify"
  }
}

# 2. Public subnet - AZ A
resource "aws_subnet" "trend_public_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name                                         = "trendify-public-subnet"
    Project                                      = "Trendify"
    "kubernetes.io/cluster/trendify-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
}

# 3. EKS public subnet - AZ B
resource "aws_subnet" "trend_eks_public_subnet" {
  vpc_id                  = aws_vpc.trend_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                         = "trendify-eks-public-subnet"
    Project                                      = "Trendify"
    "kubernetes.io/cluster/trendify-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = "1"
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "trend_igw" {
  vpc_id = aws_vpc.trend_vpc.id

  tags = {
    Name    = "trendify-igw"
    Project = "Trendify"
  }
}

# 5. Public route table
resource "aws_route_table" "trend_public_rt" {
  vpc_id = aws_vpc.trend_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.trend_igw.id
  }

  tags = {
    Name    = "trendify-public-route-table"
    Project = "Trendify"
  }
}

# 6. First subnet route association
resource "aws_route_table_association" "trend_public_rta" {
  subnet_id      = aws_subnet.trend_public_subnet.id
  route_table_id = aws_route_table.trend_public_rt.id
}

# 7. Second subnet route association
resource "aws_route_table_association" "trend_eks_public_rta" {
  subnet_id      = aws_subnet.trend_eks_public_subnet.id
  route_table_id = aws_route_table.trend_public_rt.id
}

# 8. Jenkins security group
resource "aws_security_group" "jenkins_sg" {
  name        = "trendify-jenkins-sg"
  description = "Security group for Trendify Jenkins"
  vpc_id      = aws_vpc.trend_vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["122.167.98.154/32"]
  }

  ingress {
    description = "Jenkins web access"
    from_port   = 8080
    to_port     = 8080
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
    Name    = "trendify-jenkins-sg"
    Project = "Trendify"
  }
}

# 9. Existing SSH key pair
resource "aws_key_pair" "trendify_key" {
  key_name   = "trendify-jenkins-key"
  public_key = file(pathexpand("~/.ssh/trendify-jenkins.pub"))

  tags = {
    Name    = "trendify-jenkins-key"
    Project = "Trendify"
  }
}

# 10. Amazon Linux AMI lookup
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 11. Existing Jenkins EC2 instance
resource "aws_instance" "jenkins_server" {
  ami                         = "ami-0f19324397f53458f"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.trend_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  key_name                    = aws_key_pair.trendify_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y java-21-amazon-corretto
    wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    dnf install -y jenkins
    systemctl enable jenkins
    systemctl start jenkins
  EOF

  tags = {
    Name    = "trendify-jenkins-server"
    Project = "Trendify"
  }
}

# 12. EKS cluster IAM role
resource "aws_iam_role" "eks_cluster_role" {
  name = "trendify-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "Trendify"
  }
}

# 13. EKS cluster policy
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 14. EKS worker-node IAM role
resource "aws_iam_role" "eks_node_role" {
  name = "trendify-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = "Trendify"
  }
}

# 15. Worker-node policies
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# 16. EKS cluster
resource "aws_eks_cluster" "trendify_eks" {
  name     = "trendify-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.trend_public_subnet.id,
      aws_subnet.trend_eks_public_subnet.id
    ]

    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Project = "Trendify"
  }
}

# 17. EKS managed worker-node group
resource "aws_eks_node_group" "trendify_nodes" {
  cluster_name    = aws_eks_cluster.trendify_eks.name
  node_group_name = "trendify-worker-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.trend_public_subnet.id,
    aws_subnet.trend_eks_public_subnet.id
  ]

  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_policy
  ]

  tags = {
    Project = "Trendify"
  }
}
