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

variable "miner_alarm_sns_topic" {
  type = string
  description = "SNS Topic name for Miner Alarms"
  default = "jurat_miner_alarms"
}

variable "alert_email" {
  type = string
  description = "Email that will receive cloudwatch alerts about the miner"
}

variable "jurat_ami" {
  type = string
  description = "AMI to use for the Jurat Miner"
  default = "ami-0445067903fd1e26e"
}

variable "jurat_public_key" {
  type = string
  description = "Public key of the service account for the jurat miner"
}

variable "private_key_path" {
  type = string
  description = "Path to the private key for the jurat miner"
}

variable "instance_name_suffix" {
  type = string
  description = "Timestamp to append to the Jurat Miner name tag"
  default = formatdate("YYYY-MM-DD-hh_mm_ss", timestamp())
}
