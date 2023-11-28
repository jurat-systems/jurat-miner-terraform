variable "instance_type" {
  type = string
  default = "t2.small"
  description = "The type of instance to start. Default is t2.small"
}

variable "key_name" {
  type = string
  description = "The name of the key pair"
}

variable "key_path" {
  type = string
  description = "The path to the public key to be used for the instance"
}

variable "aws_region" {
  type = string
  description = "Region in which resources exist with AWS"
}

variable "aws_account_id" {
  type = string
  description = "AWS account ID to be used"
}