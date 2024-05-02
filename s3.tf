# This Terraform code creates an AWS S3 bucket, configures public access settings, and applies a bucket policy.
# The bucket name is specified as "my-bucket-mrunal" and can be replaced with a desired bucket name.
# The "aws_s3_bucket" resource creates the S3 bucket.
# The "aws_s3_bucket_public_access_block" resource configures public access settings for the bucket.
# The "aws_s3_bucket_policy" resource applies a bucket policy that allows public read access to objects in the bucket.
# The bucket policy allows the "s3:GetObject" action for all principals ("*") on objects within the bucket.

resource "aws_s3_bucket" "bucket" {
  bucket = "my-bucket-mrunal" 
}

resource "aws_s3_bucket_public_access_block" "access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls   = false
  block_public_policy = false
  ignore_public_acls  = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.bucket.bucket}/*"
    }
  ]
}
POLICY
}