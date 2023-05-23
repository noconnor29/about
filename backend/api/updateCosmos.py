import logging
import os
import azure.functions as azfunc
from azure.cosmos import exceptions, CosmosClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

def main(req: azfunc.HttpRequest) -> azfunc.HttpResponse:
    # Get the request body (if required)
    # req_body = req.get_json()

    # Get the configuration details from Azure Key Vault
    key_vault_name = os.environ['AzureKeyVaultName']
    key_vault_uri = os.environ['AzureKeyVaultUri']
    secret_name = os.environ['CosmosDbSecretName'] # name of secret containing uri and key
    cosmosdb_uri = get_secret_from_keyvault(key_vault_uri, secret_name, 'uri')
    cosmosdb_key = get_secret_from_keyvault(key_vault_uri, secret_name, 'key')
    database_name = os.environ['CosmosDbDatabaseName'] # db
    container_name = os.environ['CosmosDbContainerName'] # visitorCount

    # Create a Cosmos DB client
    client = CosmosClient(cosmosdb_uri, credential=cosmosdb_key)
    database = client.get_database_client(database_name)
    container = database.get_container_client(container_name)

    # Query Cosmos DB to get the current value of 'visits'
    query = f"SELECT * FROM c WHERE c.id = 'counter'"
    items = list(container.query_items(query, enable_cross_partition_query=True))
    if len(items) == 0:
        # 'counter' document not found, create a new one
        counter_doc = {
            'id': 'count',
            'visits': 1
        }
        container.create_item(counter_doc)
    else:
        # Increment the 'visits' value by 1
        counter_doc = items[0]
        counter_doc['visits'] += 1
        container.replace_item(counter_doc['_self'], counter_doc)

    return azfunc.HttpResponse(f"{counter_doc['visits']}",
                             status_code=200)

def get_secret_from_keyvault(vault_uri, secret_name, secret_version):
    credential = DefaultAzureCredential()
    secret_client = SecretClient(vault_url=vault_uri, credential=credential)
    secret = secret_client.get_secret(secret_name, secret_version)
    return secret.value