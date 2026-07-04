#!/bin/bash

# AWS OIDC Setup Script for GitHub Actions
# This script creates an IAM role that GitHub Actions can assume via OIDC

set -e

# Variables
ROLE_NAME="TerraformGitHubRole"
POLICY_NAME="TerraformPolicy"
GITHUB_REPO_OWNER="kalamkarkishor1993"  # Change to your GitHub username
GITHUB_REPO_NAME="tf1"                   # Change to your repo name

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $ACCOUNT_ID"

# Step 1: Create OIDC Provider (only if it doesn't exist)
echo "Creating GitHub OIDC Provider..."
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  2>/dev/null || echo "OIDC Provider already exists"

# Step 2: Create Trust Policy JSON
cat > /tmp/trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}:ref:refs/heads/main"
        }
      }
    }
  ]
}
EOF

# Step 3: Create IAM Role
echo "Creating IAM Role: $ROLE_NAME..."
aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document file:///tmp/trust-policy.json \
  2>/dev/null || echo "Role already exists, updating trust policy..."

# Update the trust policy if role exists
aws iam update-assume-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-document file:///tmp/trust-policy.json

# Step 4: Attach Policy to Role
echo "Attaching policy to role..."

# Create inline policy for Terraform operations
cat > /tmp/terraform-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:*",
        "s3:*",
        "dynamodb:*",
        "rds:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "$POLICY_NAME" \
  --policy-document file:///tmp/terraform-policy.json

# Step 5: Display the Role ARN
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
echo ""
echo "✅ Setup Complete!"
echo "================================"
echo "Role ARN: $ROLE_ARN"
echo "================================"
echo ""
echo "Update your GitHub Actions workflow with:"
echo "  role-to-assume: $ROLE_ARN"
echo ""
echo "Also update .github/workflows/terraform.yml and replace:"
echo "  ACCOUNT_ID with $ACCOUNT_ID"

# Cleanup
rm /tmp/trust-policy.json /tmp/terraform-policy.json
