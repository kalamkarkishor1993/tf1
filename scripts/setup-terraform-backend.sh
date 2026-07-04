#!/bin/bash
set -euo pipefail

REGION="ap-south-1"
DYNAMODB_TABLE="tf1-terraform-locks"
AWS_PROFILE="${AWS_PROFILE:-default}"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="tf1-terraform-state-${ACCOUNT_ID}"

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI is required but not installed." >&2
  exit 1
fi

if ! aws sts get-caller-identity >/dev/null 2>&1; then
  echo "AWS credentials are not configured. Please run 'aws configure' or export AWS credentials." >&2
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if aws s3api head-bucket --bucket "$STATE_BUCKET" >/dev/null 2>&1; then
  echo "Bucket $STATE_BUCKET already exists."
else
  aws s3 mb "s3://$STATE_BUCKET" --region "$REGION"
  aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" --versioning-configuration Status=Enabled
fi

if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$REGION" >/dev/null 2>&1; then
  echo "DynamoDB table $DYNAMODB_TABLE already exists."
else
  aws dynamodb create-table \
    --table-name "$DYNAMODB_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$REGION"
fi

cat > backend.hcl <<EOF
bucket         = "$STATE_BUCKET"
key            = "terraform.tfstate"
region         = "$REGION"
dynamodb_table = "$DYNAMODB_TABLE"
encrypt        = true
EOF

echo "Terraform backend configured successfully."
echo "Backend file created: backend.hcl"
echo "S3 bucket: s3://$STATE_BUCKET"
echo "DynamoDB table: $DYNAMODB_TABLE"
echo "Account ID: $ACCOUNT_ID"
