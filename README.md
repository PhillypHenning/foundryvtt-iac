# FoundryVTT Terraform IaC
With the minimal setup this infrastructure will ensure you have a low cost and safe game night. The EFT is optional but recommended to ensure resilient data storage of your Rules, Worlds, etc etc

Another optional option, though perhaps not recommended, is to register a Domain Name and tie the whole thing together. (It's surprisingly not expensive to buy one.. just saying)

## Getting started

### Update the providers.tf
Either remove the S3 connection in favor of a local state file path.

### Initialize Terraform
```bash
terraform init
```

### Run a Plan
```bash
terraform plan
```

If you're comfortable with the plan and everything is coming up as successful than move on to

### Run apply
```bash
terraform apply
```


## Setting up Foundry Access to S3 bin

The `foundry_botuser` resources are responsible for access to the S3 files and images. Begin by adding the arn in the `foundry_botuser_s3_policy` to whatever data you'd like Foundry to have access to. After running `terraform apply` run `terraform output; terraform output user_secret_key`, take the two values and add them to the options.json file. 


```json
{
    "buckets": [
        "your-bucket-here"
    ],
    "region": "us-east-1",
    "credentials": {
        "accessKeyId": "access-key-it", # <-- Add the output here
        "secretAccessKey": "secret-access-key" # <-- and here
    }
}
```

