import json

def lambda_handler(event, context):
    path = event.get("path", "")

    if "/solicitar_url_envio" in path:
        return {
            "statusCode": 200,
            "body": json.dumps({"url": "https://example.com/envio"})
        }
    elif "/solicitar_url_imagens" in path:
        return {
            "statusCode": 200,
            "body": json.dumps({"url": "https://example.com/imagens"})
        }
    else:
        return {
            "statusCode": 404,
            "body": json.dumps({"message": "Endpoint not found"})
        }