
Terraform snippets for InCreator

Files included:
- provider.tf
- variables.tf
- backend.tf (commented)
- s3.tf
- dynamodb.tf
- iam.tf
- ecs_cluster.tf
- rds.tf
- notes_pinecone.md

Before running:
- Fill subnet IDs and any VPC/security groups
- Configure backend.tf if you want remote state
- Run `terraform init` then `terraform plan`
