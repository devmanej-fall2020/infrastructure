
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


resource "aws_security_group" "loadbalancer_security_group" {
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.assignmentvpc.id



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

  egress {
    description = "Port 4000"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block_map["cidr_route"]]
  }

  # egress {
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  #}

  tags = {
    Name = "loadbalancer_security_group"
  }

}

resource "aws_security_group" "webapp_security_group" {
  description = "Allow inbound traffic"
  vpc_id      = aws_vpc.assignmentvpc.id

  # ingress {
  #   description = "Port 22"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.cidr_block_map["cidr_route"]]
  # }

  # ingress {
  #   description = "Port 80"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = [var.cidr_block_map["cidr_route"]]
  # }

  # ingress {
  #   description = "Port 443"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = [var.cidr_block_map["cidr_route"]]
  # }

  ingress {
    description = "Allow Load Balancer Access"
    from_port   = 4000
    to_port     = 4000
    protocol    = "tcp"
    security_groups = [aws_security_group.loadbalancer_security_group.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "webapp_security_group"
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
    security_groups = [aws_security_group.webapp_security_group.id]
}


  tags = {
    Name = "database_security_group"
  }
}


resource "aws_s3_bucket" "assignmentbucket" {
  bucket = var.s3_image_bucket
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


# resource "aws_instance" "ec2instance-assignment" {
#   ami = data.aws_ami.amigetfunction.id
#   instance_type = "t2.micro"
#   key_name = var.cred_vars["key_name"]
#   vpc_security_group_ids = [aws_security_group.webapp_security_group.id]
#   subnet_id = aws_subnet.subnet1.id
#   iam_instance_profile = aws_iam_instance_profile.ec2_iam_ip.name
#   associate_public_ip_address = true
#   disable_api_termination = false

#   user_data = <<-EOF
#                 #!/bin/bash
#                 sudo touch .env\n
#                 sudo echo "export RDS_DB_USERNAME=${var.cred_vars["username"]}" >> /etc/environment
#                 sudo echo "export RDS_DB_PASSWORD=${var.cred_vars["password"]}" >> /etc/environment
#                 sudo echo "export RDS_DB_HOSTNAME=${aws_db_instance.rdsassignmentdb.address}" >> /etc/environment
#                 sudo echo "export S3_BUCKET_NAME=${aws_s3_bucket.assignmentbucket.bucket}" >> /etc/environment
#                 sudo echo "export RDS_DB_ENDPOINT=${aws_db_instance.rdsassignmentdb.endpoint}" >> /etc/environment
#                 sudo echo "export RDS_DB_NAME=${aws_db_instance.rdsassignmentdb.name}" >> /etc/environment
#   EOF


#   root_block_device {
#       volume_type = "gp2"
#       volume_size =  20
#       delete_on_termination = true
#   }
#   tags = {
#     Name = "ec2instance-assignment"
#   }
# }

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
            "Resource": ["arn:aws:s3:::${var.s3_image_bucket}"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::${var.s3_image_bucket}/*"]
        }
    ]
}
EOF
}


resource "aws_iam_instance_profile" "ec2_iam_ip" {
  name = "test1_profile"
  role = aws_iam_role.CodeDeployEC2ServiceRole.name
}

//ec2 role to pass on access to s3 buckets without explicitly specifying credentials
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

//codedeploy_ec2_service_role definition
resource "aws_iam_role" "CodeDeployEC2ServiceRole" {
  name = "CodeDeployEC2ServiceRole"

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




//wa_s3 policy attachment
resource "aws_iam_policy_attachment" "attachement" {
  name       = "Policy Attachment"
  roles      = [aws_iam_role.CodeDeployEC2ServiceRole.name]
  policy_arn = aws_iam_policy.wa_s3_policy.arn
}

//CodeDeploy-EC2-S3 IAM Policy attachment to CodeDeployEC2ServiceRole role
resource "aws_iam_policy_attachment" "codedeploy_ec2_s3_policy_attachment" {
  name       = "Policy Attachment"
  roles      = [aws_iam_role.CodeDeployEC2ServiceRole.name]
  policy_arn = aws_iam_policy.CodeDeploy-EC2-S3.arn
}



// getting data of ghactions iam user
data "aws_iam_user" "ghactions_user" {
  user_name = "ghactions"
}

//new policies to be added
# CodeDeploy-EC2-S3 IAM Policy
resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = "CodeDeploy-EC2-S3"
  path        = "/"
  description = "CodeDeploy-EC2-S3 policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:GetObject",
                "s3:List*",
                "s3:Put*",
                "s3:PutObject"


            ],
            "Effect": "Allow",
            "Resource": [
              "arn:aws:s3:::${var.codedeploy_bucket}",
              "arn:aws:s3:::${var.codedeploy_bucket}/*"
              ]
        }
    ]
}
EOF
}

//attachment of GH-Upload-To-S3 IAM Policy to ghactions_user
resource "aws_iam_user_policy_attachment" "ghactions_attach_gh_upload_to_s3_policy" {
  user       = data.aws_iam_user.ghactions_user.user_name
  policy_arn = aws_iam_policy.GH-Upload-To-S3.arn
}


# GH-Upload-To-S3 IAM Policy
resource "aws_iam_policy" "GH-Upload-To-S3" {
  name        = "GH-Upload-To-S3"
  path        = "/"
  description = "GH-Upload-To-S3 policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:Put*",
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": [
              "arn:aws:s3:::${var.codedeploy_bucket}",
              "arn:aws:s3:::${var.codedeploy_bucket}/*"
            ]
        }
    ]
}
EOF
}

data "aws_caller_identity" "current_user_details" {}


//CodeDeployServiceRole, will be utilizing the codedeploy service
resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

//adding policy of default policy AWSCodeDeployRole to CodeDeployServiceRole
resource "aws_iam_role_policy_attachment" "AWSCodeDeployRole" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.CodeDeployServiceRole.name
}

//defining the codedeploy app
resource "aws_codedeploy_app" "csye6225-webapp" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}

//codedeploy group
resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name              = aws_codedeploy_app.csye6225-webapp.name
  deployment_group_name = "csye6225-webapp-deployment"
  service_role_arn      = aws_iam_role.CodeDeployServiceRole.arn
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  autoscaling_groups = [aws_autoscaling_group.asg_webapp.name]
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.application-target-group.name
    }
  }


  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "ec2instance-assignment"
    }
  }


}






# GH-Code-Deploy Policy
resource "aws_iam_policy" "GH-Code-Deploy" {
  name        = "GH-Code-Deploy"
  description = "GH-Code-Deploy policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.current_region}:${data.aws_caller_identity.current_user_details.account_id}:application:${var.codedeploy_application_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.current_region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentgroup:${var.codedeploy_application_name}/${var.codedeploy_group_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.current_region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.current_region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.current_region}:${data.aws_caller_identity.current_user_details.account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}

//attachment of GH-Code-Deploy IAM Policy to ghactions_user
resource "aws_iam_user_policy_attachment" "ghactions_attach_ghcodedeploy_policy" {
  user       = data.aws_iam_user.ghactions_user.user_name
  policy_arn = aws_iam_policy.GH-Code-Deploy.arn
}

//creating an elastic ip
# resource "aws_eip" "elastic_ip" {
#   instance = aws_instance.ec2instance-assignment.id
#   vpc      = true
# }

//fetching data which contains route 53 zone id
data "aws_route53_zone" "fetched_zone" {
  name         = var.domain
  private_zone = false
}


//create a type record from eip
resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.fetched_zone.zone_id
  name    = "www.api.${data.aws_route53_zone.fetched_zone.name}"
  type    = "A"

  alias {
    name                   = aws_lb.assignment-load-balancer.dns_name
    zone_id                = aws_lb.assignment-load-balancer.zone_id
    evaluate_target_health = true
  }
}




//adding dynamo db resource
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

# //adding policy of AWSCloudWatchAgentServerPolicy to CodeDeployEC2ServiceRole role
resource "aws_iam_role_policy_attachment" "CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.CodeDeployEC2ServiceRole.name
}

#launch config
resource "aws_launch_configuration" "asg_launch_config" {
  name_prefix   = "asg_launch_config"
  image_id      = data.aws_ami.amigetfunction.id
  instance_type = "t2.micro"
  key_name = var.cred_vars["key_name"]
  security_groups = [aws_security_group.webapp_security_group.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_ip.name


  user_data = <<-EOF
                #!/bin/bash
                sudo touch .env\n
                sudo echo "export RDS_DB_USERNAME=${var.cred_vars["username"]}" >> /etc/environment
                sudo echo "export RDS_DB_PASSWORD=${var.cred_vars["password"]}" >> /etc/environment
                sudo echo "export RDS_DB_HOSTNAME=${aws_db_instance.rdsassignmentdb.address}" >> /etc/environment
                sudo echo "export S3_BUCKET_NAME=${aws_s3_bucket.assignmentbucket.bucket}" >> /etc/environment
                sudo echo "export RDS_DB_ENDPOINT=${aws_db_instance.rdsassignmentdb.endpoint}" >> /etc/environment
                sudo echo "export RDS_DB_NAME=${aws_db_instance.rdsassignmentdb.name}" >> /etc/environment
  EOF


  lifecycle {
    create_before_destroy = true
  }


}

resource "aws_autoscaling_group" "asg_webapp" {
  name                 = "asg_webapp"
  launch_configuration = aws_launch_configuration.asg_launch_config.name
  min_size             = 3
  max_size             = 5
  desired_capacity     = 3
  default_cooldown     = 60
  target_group_arns = [aws_lb_target_group.application-target-group.arn]
  vpc_zone_identifier  = [aws_subnet.subnet1.id, aws_subnet.subnet2.id,aws_subnet.subnet3.id]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "ec2instance-assignment"
    propagate_at_launch = true
  }


}

//Scale-Up Policy
resource "aws_autoscaling_policy" "WebServerScaleUpPolicy" {
  name                   = "WebServerScaleUpPolicy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg_webapp.name
}

//Scale-Down Policy
resource "aws_autoscaling_policy" "WebServerScaleDownPolicy" {
  name                   = "WebServerScaleDownPolicy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.asg_webapp.name
}

//Alarm for CPU High
resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = "CPUAlarmHigh"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "5"
  alarm_description = "Scale-up if CPU > 5% for 300 seconds"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_webapp.name
  }
 
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleUpPolicy.arn]
}

//Alarm for CPU Low
resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name          = "CPUAlarmLow"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "3"
  alarm_description = "Scale-down if CPU < 3% for 300 seconds"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_webapp.name
  }
 
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleDownPolicy.arn]
}

//Load Balancer
resource "aws_lb" "assignment-load-balancer" {
  name               = "assignment-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer_security_group.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id,aws_subnet.subnet3.id]

  enable_deletion_protection = false

  tags = {
    Name = "ec2instance-assignment"
  }

}

//Load Balancer Listener
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.assignment-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application-target-group.arn
  }
}

resource "aws_lb_target_group" "application-target-group" {
  name     = "application-target-group"
  port     = 4000
  protocol = "HTTP"

  health_check {
    port = 4000
    matcher = 200
    path = "/"
  }
  vpc_id   = aws_vpc.assignmentvpc.id
}








