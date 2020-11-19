variable "a_zones_subnet_map" {
  type = map(string)

  default = {
    "zone1" = "us-east-1a"
    "zone2" = "us-east-1b"
    "zone3" = "us-east-1c"
    
  }
}

variable "cidr_block_map" {
  type = map(string)

  default = {
    "cidr1" = "10.0.1.0/24"
    "cidr2" = "10.0.2.0/24"
    "cidr3" = "10.0.3.0/24"
    "cidr_vpc" = "10.0.0.0/16"
    "cidr_route" = "0.0.0.0/0"
    
  }
}

variable "current_region"{
    default = "us-east-1"
}


variable "codedeploy_application_name"{
  default = "csye6225-webapp"
}

variable "codedeploy_group_name"{
  default = "csye6225-webapp-deployment"
}


variable "cred_vars" {
  type = map(string)

  default = {
    "username" = "csye6225fall2020"
    "password" = "Cloud456!"
    "name" = "csye6225"
    "identifier" = "csye6225-f20"
    "key_name" = "csye6225-aws-fall2020"
  }
}


//change variable name accordingly for dev and prod
variable "s3_image_bucket" {
  default = "webapp.jaisubash.devmane"
}



//comment out for either case
//prod codedeploy bucket
variable "codedeploy_bucket"{
  default = "codedeploy.prod.jaisubashdevmane.me"
}

//comment out for either case
//dev codedeploy bucket
# variable "codedeploy_bucket"{
#   default = "codedeploy.dev.jaisubashdevmane.me"
# }




//comment out for either case
//dev domain
# variable "domain"{
#   default = "dev.jaisubashdevmane.me"
# }

# //prod domain
variable "domain"{
  default = "prod.jaisubashdevmane.me"
}