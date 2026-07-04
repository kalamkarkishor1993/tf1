# AWS OIDC Setup with GitHub Actions

This guide helps you set up OpenID Connect (OIDC) authentication between GitHub Actions and AWS for your Terraform deployments.

## Why OIDC?

✅ No hardcoded AWS credentials in your code  
✅ Short-lived tokens (1 hour default)  
✅ Automatic audit trail in CloudTrail  
✅ Fine-grained access control per repository/branch  

## Setup Steps

### 1. Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

Save this ID - you'll need it for the next steps.

### 2. Run the Setup Script

```bash
chmod +x setup-aws-oidc.sh
./setup-aws-oidc.sh
```

This script will:
- Create an OIDC provider that trusts GitHub
- Create an IAM role (`TerraformGitHubRole`)
- Attach necessary permissions
- Output the Role ARN

### 3. Update Your Workflow

In `.github/workflows/terraform.yml`, replace `ACCOUNT_ID` with your actual AWS Account ID:

```yaml
role-to-assume: arn:aws:iam::123456789012:role/TerraformGitHubRole
```

### 4. Commit and Push

```bash
git add .
git commit -m "Add OIDC authentication for GitHub Actions"
git push origin main
```

## How It Works

```
GitHub Actions
    ↓
Request token from GitHub's OIDC provider
    ↓
AWS checks token signature & claims
    ↓
Assumes IAM role (if trust policy matches)
    ↓
Returns temporary AWS credentials
    ↓
Terraform uses credentials to create/update resources
```

## Verification

Check that your workflow ran successfully:
1. Push a commit to your repo
2. Go to **Actions** tab in GitHub
3. Click on the workflow run
4. Check the **Configure AWS credentials** step
5. Should show: ✅ "Credentials configured successfully"

## Customizing Permissions

Edit `setup-aws-oidc.sh` to adjust IAM permissions:

```json
{
  "Effect": "Allow",
  "Action": [
    "ec2:*",           // EC2 instances
    "iam:*",           // IAM roles/policies
    "s3:*",            // S3 buckets
    "dynamodb:*",      // DynamoDB tables
    "rds:*"            // RDS databases
  ],
  "Resource": "*"
}
```

Replace with only the services your Terraform code uses.

## Security Best Practices

1. **Restrict by Branch**
   ```json
   "token.actions.githubusercontent.com:sub": "repo:owner/repo:ref:refs/heads/main"
   ```

2. **Restrict by Environment**
   ```json
   "token.actions.githubusercontent.com:sub": "repo:owner/repo:environment:Production"
   ```

3. **Use least privilege** - Only grant needed IAM permissions

4. **Monitor** - Check CloudTrail for `AssumeRoleWithWebIdentity` calls

## Troubleshooting

### "User is not authorized to perform: sts:AssumeRoleWithWebIdentity"
- Verify the trust policy includes your repository
- Check Role ARN in workflow matches actual role

### "Credentials configured but API calls fail"
- IAM policy might be missing permissions
- Check the specific resource ARN in error message
- Update the policy with that resource

### Role not found
- Ensure `setup-aws-oidc.sh` completed successfully
- Verify role name in AWS IAM console

## Cleanup

To remove the OIDC setup:

```bash
aws iam delete-role-policy --role-name TerraformGitHubRole --policy-name TerraformPolicy
aws iam delete-role --role-name TerraformGitHubRole
```

## Next Steps

- Monitor deployments in GitHub Actions
- Scale to multiple environments (staging, production)
- Add approval gates for `main` branch deployments
- Set up Terraform state locking with DynamoDB

---

For more info: https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
