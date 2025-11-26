
resource "aws_s3_bucket" "raw_bucket" {
  bucket = format("%s-raw-%s", var.project, var.env)
  acl    = "private"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "archive-old"
    enabled = true

    prefix = ""
    expiration {
      days = 365
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}
