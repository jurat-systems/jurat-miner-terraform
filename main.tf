terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = "1.6.0"
}

resource "aws_key_pair" "jurat_key_pair" {
  key_name = "jurat_key"
  public_key = "~/.ssh/jurat_ec2_key.pem.pub"
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
  ami           = "jurat-ami"
  instance_type = var.instance_type
  key_name      = jurat_key_pair.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = 1000
  }

  vpc_security_group_ids = [aws_security_group.jurat_sg.id]

  tags = {
    Name = "JuratMiner"
  }
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

  alarm_actions = ["arn:aws:sns:your-region:your-account-id:your-sns-topic"]
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

  alarm_actions = ["arn:aws:sns:your-region:your-account-id:your-sns-topic"]
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

  alarm_actions = ["arn:aws:sns:your-region:your-account-id:your-sns-topic"]
}