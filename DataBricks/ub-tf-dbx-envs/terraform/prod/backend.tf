terraform {
  backend "s3" {
    bucket         = "urbint-terraform-state"     # <- replace bucket name as per your state file  bucket name 
    key            = "dbx-envs/prod/terraform.tfstate"
    region         = "us-east-2"                   # <- replace region as per required region
    encrypt        = true
  }
}

