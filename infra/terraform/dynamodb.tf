
resource "aws_dynamodb_table" "feature_store" {
  name         = "${var.project}-featurestore-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "creator_id"

  attribute {
    name = "creator_id"
    type = "S"
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}
