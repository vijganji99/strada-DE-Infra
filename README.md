# strada-DE-Infra
For STRADA team Azure Infra set up via Automation using Azure Terraform
```mermaid
graph TD;
    SQLSERVER-->ADF;
ADF-->ADB;
    ADB-->ASADL;
    
    C-->D;
```

## Explanation of architecture and azure infra and the azure services connectivity

Provision separate environments (dev, tst, prd) for a new STRADA downstream data team at Van Lanschot Kempen . This team will need the following Azure services:
•	Azure Databricks
•	Storage Account
•	Data Factory
•	Key Vault
•	SQL Server

Basically , the whole architecture of this project as I assume:

1. Starts with data from SQL Server (assuming On-Prem SQL Server) data ingestion into Azure Data Factory(ADF) via ADF Pipelines service. This is done by creating a Linked Server from ADF to SQL Server using the credentials created at SQL Server.
2. Next step is ADF to Azure Data Lake(ADL) and Azure Data Bricks Services (ADB) using Azure Entra ID service principal credentials.
3. Azure Data Bricks is connected to Azure Data Lake via a Service Principal created at Entra ID and by granting necessary access to service principal for Azure storage account container( which is made as data lake by enabling the Hirearchial namespace option).
4. During all this process we can use Azure Key Vault to store the Credentials from SQL Server or PAT function

