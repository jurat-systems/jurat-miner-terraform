terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = "1.6.0"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "jurat_key_pair" {
  key_name = "jurat_key"
  public_key = var.jurat_public_key
}

resource "aws_security_group" "jurat_sg" {
  name        = "jurat-sg"
  description = "Security group for Jurat Miners"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 9333
    to_port     = 9333
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Jurat Blockchain"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
}

resource "aws_instance" "jurat_miner" {
  ami           = var.jurat_ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.jurat_key_pair.key_name

  depends_on = [
    aws_key_pair.jurat_key_pair,
    aws_security_group.jurat_sg
  ]

  #root_block_device {
  #  volume_type = "gp3"
  #  volume_size = 8
  #}

  vpc_security_group_ids = [aws_security_group.jurat_sg.id]

  tags = {
    Name = "JuratMiner-${var.instance_name_suffix}"
  }

  provisioner "file" {
    source = "walletaddress"
    destination = "/satoshi/walletaddress"

    connection {
      type = "ssh"
      user = "admin"
      private_key = file(var.private_key_path)
      host = self.public_ip
    }
  }
}

output "instance_public_ip" {
  description = "Public IP address of the Jurat-Miner instance"
  value       = aws_instance.jurat_miner.public_ip
}

resource "aws_sns_topic" "miner_sns_topic" {
  name = var.miner_alarm_sns_topic
}

resource "aws_sns_topic_subscription" "email_alert_subscription" {
  topic_arn = aws_sns_topic.miner_sns_topic.arn
  protocol = "email"
  endpoint = var.alert_email
}

resource "aws_cloudwatch_metric_alarm" "instance_status_check" {
  alarm_name          = "InstanceStatusCheckFailure"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors EC2 instance status checks failure"
  actions_enabled     = true

  dimensions = {
    InstanceId = aws_instance.jurat_miner.id
  }

  alarm_actions = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.miner_alarm_sns_topic}"]
}

resource "aws_cloudwatch_metric_alarm" "disk_usage_alarm_80" {
  alarm_name          = "DiskUsageAlarm80"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors disk usage exceeding 80%"
  actions_enabled     = true

  dimensions = {
    InstanceId = aws_instance.jurat_miner.id
    path       = "/"
    fstype     = "ext4"  # Modify this based on your file system type
  }

  alarm_actions = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.miner_alarm_sns_topic}"]
}

resource "aws_cloudwatch_metric_alarm" "disk_usage_alarm_90" {
  alarm_name          = "DiskUsageAlarm90"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = "60"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "This metric monitors disk usage exceeding 90%"
  actions_enabled     = true

  dimensions = {
    InstanceId = aws_instance.jurat_miner.id
    path       = "/"
    fstype     = "ext4"  # Modify this based on your file system type
  }

  alarm_actions = ["arn:aws:sns:${var.aws_region}:${var.aws_account_id}:${var.miner_alarm_sns_topic}"]
}
