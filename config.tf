
resource "aws_config_configuration_recorder" "recorder" {
  name     = "default"
  role_arn = aws_iam_role.role.arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_iam_role" "role" {
  name = "awsconfig"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_config_delivery_channel" "channel" {
  name           = "default"
  s3_bucket_name = aws_s3_bucket.bucket.bucket
  s3_key_prefix  = "config"
  sns_topic_arn  = aws_sns_topic.topic.arn
}

resource "aws_s3_bucket" "bucket" {
  bucket = "mrunal-aws-config" 
}

resource "aws_sns_topic" "topic" {
  name = "mrunal-cfg-topic" 
}

resource "aws_config_config_rule" "rule" {
  name = "example"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.recorder]
}
