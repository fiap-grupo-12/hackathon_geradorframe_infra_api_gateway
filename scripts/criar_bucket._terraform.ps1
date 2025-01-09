# Nome do bucket e região
$bucketName = "terraform-tfstate-grupo12-fiap-2024-cesar1"
$region = "us-east-1"

# Comando para criar o bucket no S3
aws s3api create-bucket `
    --bucket $bucketName `
    --region $region `

# Mensagem de confirmação
Write-Output "Bucket '$bucketName' criado com sucesso na região '$region'."

# Configuração de versão (opcional para segurança do estado do Terraform)
aws s3api put-bucket-versioning `
    --bucket $bucketName `
    --versioning-configuration Status=Enabled

Write-Output "Versionamento habilitado no bucket '$bucketName'."

# Configuração de bloqueio de acesso público (opcional para segurança)
try {
    aws s3api put-public-access-block `
        --bucket $bucketName `
        --public-access-block-configuration `
        BlockPublicAcls=true `

    Write-Output "Políticas de acesso público configuradas para o bucket '$bucketName'."
} catch {
    Write-Output "Erro ao configurar políticas de acesso público: $_"
}