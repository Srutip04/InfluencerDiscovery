
output "s3_raw_bucket" {
  value = aws_s3_bucket.raw_bucket.id
}

output "dynamodb_feature_table" {
  value = aws_dynamodb_table.feature_store.name
}
