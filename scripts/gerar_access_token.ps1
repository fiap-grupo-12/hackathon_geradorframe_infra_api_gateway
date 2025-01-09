# # OPÇÃO 1	
# $client_id = "****" # ID do cliente configurado no Cognito
# $authorization_code = "****"  # O código de autorização que você recebeu
# $token_url = "https://<domain>.auth.us-east-1.amazoncognito.com/oauth2/token"
# $client_secret = "*****"
# $redirect_uri = "http://localhost"

# $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
# $headers.Add("Content-Type", "application/x-www-form-urlencoded")
# $headers.Add("Cookie", "XSRF-TOKEN=c37ed6cb-ee5d-4ab5-a19d-442e9a94e421")

# $body = "grant_type=authorization_code&client_id=$client_id&code=$authorization_code&client_secret=$client_secret&redirect_uri=$redirect_uri"

# $response = Invoke-RestMethod 'https:/<domain>.auth.us-east-1.amazoncognito.com/oauth2/token' -Method 'POST' -Headers $headers -Body $body
# $response | ConvertTo-Json

# #OPÇÃO 2 - bash - cloudshell da AWS
# USERNAME="cesaraperes@gmail.com"  # Substitua pelo nome de usuário
# CLIENT_ID="9gi2otrj9kr5uklr30feh6s1o"  # Substitua pelo seu Client ID
# PASSWORD="123456"
# USER_POOL_ID="us-east-1_8Xect6SFD"  # Substitua pelo seu User Pool ID
# aws cognito-idp admin-initiate-auth --user-pool-id $USER_POOL_ID --client-id $CLIENT_ID --auth-flow ADMIN_NO_SRP_AUTH --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD

#OPÇÃO 3 - Powershell 
# Defina as variáveis
$USERNAME = ""  # Substitua pelo nome de usuário
$CLIENT_ID = "5mkiipedoc60p0fot6ebkn4vn8"  # Substitua pelo seu Client ID
$PASSWORD = "123456"
$USER_POOL_ID = "us-east-1_nz4mcgIwz"  # Substitua pelo seu User Pool ID

# Execute o comando AWS CLI
aws cognito-idp admin-initiate-auth `
    --user-pool-id $USER_POOL_ID `
    --client-id $CLIENT_ID `
    --auth-flow ADMIN_NO_SRP_AUTH `
    --auth-parameters USERNAME=$USERNAME,PASSWORD=$PASSWORD
