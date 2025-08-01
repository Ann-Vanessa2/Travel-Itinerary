variable "project_prefix" {
  default = "travel-itinerary-a"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "azs" {
  default = ["eu-west-1a", "eu-west-1b"]
}

variable "db_username" {}
variable "db_password" {}
variable "redshift_password" {}