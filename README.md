# FoundryVTT Terraform IaC
With the minimal setup this infrastructure will ensure you have a low cost and safe game night. The EFT is optional but recommended to ensure resilient data storage of your Rules, Worlds, etc etc

Another optional option, though perhaps not recommended, is to register a Domain Name and tie the whole thing together. (It's surprisingly not expensive to buy one.. just saying)

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

