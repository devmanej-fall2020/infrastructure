
provider "aws" {
    region = var.current_region
}

resource "aws_vpc" "assignmentvpc" {
  cidr_block       = var.cidr_block_map["cidr_vpc"]
  enable_dns_hostnames = true
  enable_dns_support = true
  enable_classiclink_dns_support = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "csye6225-vpc"
  }
}

resource "aws_subnet" "subnet1" {
    cidr_block = var.cidr_block_map["cidr1"]
    vpc_id     = aws_vpc.assignmentvpc.id
    availability_zone = var.a_zones_subnet_map["zone1"]
    map_public_ip_on_launch = true
    tags = {
    Name = "subnet-1"
  }
}

resource "aws_subnet" "subnet2" {
    cidr_block = var.cidr_block_map["cidr2"]
    vpc_id     = aws_vpc.assignmentvpc.id
    availability_zone = var.a_zones_subnet_map["zone2"]
    map_public_ip_on_launch = true
  tags = {
    Name = "subnet-2"
  }
}

resource "aws_subnet" "subnet3" {
    cidr_block = var.cidr_block_map["cidr3"]
    vpc_id     = aws_vpc.assignmentvpc.id
    availability_zone = var.a_zones_subnet_map["zone3"]
    map_public_ip_on_launch = true

  tags = {
    Name = "subnet-3"
  }
}

resource "aws_internet_gateway" "i_gateway" {
  vpc_id = aws_vpc.assignmentvpc.id

  tags = {
    Name = "i_gateway"
  }
}

resource "aws_route_table" "r_table" {
  vpc_id = aws_vpc.assignmentvpc.id



  route {
    cidr_block = var.cidr_block_map["cidr_route"]
    gateway_id = aws_internet_gateway.i_gateway.id
  }

  tags = {
    Name = "r_table"
  }
}


resource "aws_route_table_association" "rt_association_1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r_table.id
}

resource "aws_route_table_association" "rt_association_2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.r_table.id
}

resource "aws_route_table_association" "rt_association_3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.r_table.id
}


resource "aws_security_group" "application_security_group" {
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.assignmentvpc.id

  ingress {
    description = "Port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  ingress {
    description = "Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  ingress {
    description = "Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  ingress {
    description = "Port 4000"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application_security_group"
  }
}


resource "aws_security_group" "database_security_group"{
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.assignmentvpc.id


  ingress {
    description = "Allow MySQL access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.application_security_group.id]
}


  tags = {
    Name = "database_security_group"
  }
}


resource "aws_s3_bucket" "assignmentbucket" {
  bucket = "webapp.jaisubash.devmane"
  acl    = "private"
  force_destroy = true


  server_side_encryption_configuration {    
    rule {     
       apply_server_side_encryption_by_default { sse_algorithm = "AES256"}
       }
  }

  lifecycle_rule {
    id      = "log"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA" # or "ONEZONE_IA"
    }
  }

  tags = {
    Name = "assignmentbucket"
  }
}

resource "aws_s3_bucket_public_access_block" "s3removePublicAccess" {
bucket = aws_s3_bucket.assignmentbucket.id
block_public_acls = true
block_public_policy = true
restrict_public_buckets = true
ignore_public_acls = true
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db_subnet_group"
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id,aws_subnet.subnet3.id]

  tags = {
    Name = "DB Subnet Group"
  }
}

resource "aws_db_instance" "rdsassignmentdb" {
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  instance_class = "db.t2.micro"
  name = var.cred_vars["name"]
  username = var.cred_vars["username"]
  password = var.cred_vars["password"]
  multi_az = false
  publicly_accessible = false
  identifier = var.cred_vars["identifier"]
  skip_final_snapshot = true
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
}

data "aws_ami" "amigetfunction" {
  owners = ["411821511450"]
  most_recent = true

}


resource "aws_instance" "ec2instance-assignment" {
  ami = data.aws_ami.amigetfunction.id
  instance_type = "t2.micro"
  key_name = var.cred_vars["key_name"]
  vpc_security_group_ids = [aws_security_group.application_security_group.id]
  subnet_id = aws_subnet.subnet1.id
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_ip.name
  associate_public_ip_address = true
  disable_api_termination = false

  user_data = <<-EOF
                #!/bin/bash
                sudo touch .env\n
                sudo echo "export RDS_DB_USERNAME=${var.cred_vars["username"]}" >> /home/ubuntu/.bashrc
                sudo echo "export RDS_DB_PASSWORD=${var.cred_vars["password"]}" >> /home/ubuntu/.bashrc
                sudo echo "export RDS_DB_HOSTNAME=${aws_db_instance.rdsassignmentdb.address}" >> /home/ubuntu/.bashrc
                sudo echo "export S3_BUCKET_NAME=${aws_s3_bucket.assignmentbucket.bucket}" >> /home/ubuntu/.bashrc
                sudo echo "export RDS_DB_ENDPOINT=${aws_db_instance.rdsassignmentdb.endpoint}" >> /home/ubuntu/.bashrc
                sudo echo "export RDS_DB_NAME=${aws_db_instance.rdsassignmentdb.name}" >> /home/ubuntu/.bashrc
  EOF


  root_block_device {
      volume_type = "gp2"
      volume_size =  20
      delete_on_termination = true
  }
  tags = {
    Name = "ec2instance-assignment"
  }
}

# IAM Policy
resource "aws_iam_policy" "wa_s3_policy" {
  name        = "WebAppS3"
  path        = "/"
  description = "WebAppS3 policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": ["s3:ListBucket"],
            "Resource": ["arn:aws:s3:::webapp.jaisubash.devmane"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::webapp.jaisubash.devmane/*"]
        }
    ]
}
EOF
}


resource "aws_iam_instance_profile" "ec2_iam_ip" {
  name = "test_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}



resource "aws_iam_policy_attachment" "attachement" {
  name       = "Policy Attachment"
  roles      = [aws_iam_role.ec2_role.name]
  policy_arn = aws_iam_policy.wa_s3_policy.arn
}



resource "aws_dynamodb_table" "assignment-dynamodb" {
  name           = "csye6225"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "assignment-dynamodb"
  }
}