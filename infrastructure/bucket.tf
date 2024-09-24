resource "aws_s3_bucket" "log_destination" {
  bucket_prefix = "mitchell-test-"
  force_destroy = true
}
