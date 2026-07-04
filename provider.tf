# provider.tf - SECURE VERSION
provider "aws" {
  region = "ap-south-1"
  
  # Credentials now come from:
  # 1. Environment variables (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
  # 2. ~/.aws/credentials file
  # 3. IAM role (when running on EC2, ECS, Lambda)
  # 4. OIDC provider (in CI/CD)
}