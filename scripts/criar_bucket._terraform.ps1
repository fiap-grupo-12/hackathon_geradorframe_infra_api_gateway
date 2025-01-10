# Nome do bucket e região
$bucketName = "terraform-tfstate-grupo12-fiap-2024-cesar-20250110"
$region = "us-east-1"

# Comando para criar o bucket no S3
aws s3api create-bucket `
    --bucket $bucketName `
    --region $region 