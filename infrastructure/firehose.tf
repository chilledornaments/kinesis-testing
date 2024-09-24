resource "aws_kinesis_firehose_delivery_stream" "to_s3" {
  destination = "extended_s3"
  name        = "stream-to-s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.this.arn
    role_arn           = aws_iam_role.firehose.arn
  }

  extended_s3_configuration {
    bucket_arn         = aws_s3_bucket.log_destination.arn
    role_arn           = aws_iam_role.firehose.arn
    buffering_interval = 30

    processing_configuration {
      enabled = true

      processors {
        type = "AppendDelimiterToRecord"

        parameters {
          parameter_name  = "Delimiter"
          parameter_value = "\\n"
        }
      }
    }
  }
}

data "aws_iam_policy_document" "firehose_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "firehose" {
  name               = "mitchell-test-firehose"
  assume_role_policy = data.aws_iam_policy_document.firehose_assume.json
}

data "aws_iam_policy_document" "firehose_actions" {
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
      "kinesis:ListShards",
    ]
    resources = [
      aws_kinesis_stream.this.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.log_destination.arn}/*",
      aws_s3_bucket.log_destination.arn,
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["*"] # TODO lazy
  }
}

resource "aws_iam_role_policy" "firehose" {
  policy = data.aws_iam_policy_document.firehose_actions.json
  role   = aws_iam_role.firehose.name
}
