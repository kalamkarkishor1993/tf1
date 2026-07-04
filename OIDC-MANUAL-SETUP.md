# AWS OIDC Setup - Manual Steps

Follow these steps to set up OIDC authentication between GitHub Actions and AWS.

## Step 1: Get Your AWS Account ID

1. Go to AWS Console: https://console.aws.amazon.com/
2. Click on your account name in the top-right corner
3. Copy your **Account ID** (12-digit number)
4. Replace `ACCOUNT_ID` in the steps below with your actual ID

## Step 2: Create OIDC Provider

Go to AWS IAM Console → Identity Providers → Add Provider:

**Provider Type:** OpenID Connect  
**Provider URL:** `https://token.actions.githubusercontent.com`  
**Audience:** `sts.amazonaws.com`  

Then click "Add Provider"

## Step 3: Create IAM Role

Go to AWS IAM Console → Roles → Create Role:

**Trusted entity type:** Web identity  
**Identity provider:** `token.actions.githubusercontent.com`  
**Audience:** `sts.amazonaws.com`  

**Trust Policy JSON:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:kalamkarkishor1993/tf1:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Replace `ACCOUNT_ID` with your 12-digit AWS Account ID.

**Role Name:** `TerraformGitHubRole`

## Step 4: Add Permissions to Role

Attach policy to the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "iam:GetRole",
        "iam:ListRolePolicies",
        "iam:GetRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

(You can expand permissions as needed for your infrastructure)

## Step 5: Update GitHub Actions Workflow

Update `.github/workflows/terraform.yml` and replace `ACCOUNT_ID` in this line:

```yaml
role-to-assume: arn:aws:iam::ACCOUNT_ID:role/TerraformGitHubRole
```

Example:
```yaml
role-to-assume: arn:aws:iam::123456789012:role/TerraformGitHubRole
```

## Step 6: Verify Setup

Push a new commit and check the GitHub Actions workflow:

```bash
git add .
git commit -m "Setup OIDC for AWS authentication"
git push origin main
```

Monitor the Actions tab - the "Configure AWS credentials" step should now succeed.

## Using AWS CLI (Alternative)

If you have AWS CLI installed locally, run these commands:

```bash
# 1. Create OIDC Provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# 2. Create Role (save trust-policy.json first)
aws iam create-role \
  --role-name TerraformGitHubRole \
  --assume-role-policy-document file://trust-policy.json

# 3. Attach Policy
aws iam put-role-policy \
  --role-name TerraformGitHubRole \
  --policy-name TerraformPolicy \
  --policy-document file://terraform-policy.json

# 4. Get Role ARN
aws iam get-role --role-name TerraformGitHubRole --query 'Role.Arn'
```

## Troubleshooting

**"No OpenIDConnect provider found"**
- Verify OIDC provider is created in IAM → Identity Providers
- URL must be exactly: `https://token.actions.githubusercontent.com`

**"User is not authorized to perform: sts:AssumeRoleWithWebIdentity"**
- Check Trust Policy conditions match your repo (`kalamkarkishor1993/tf1`)
- Verify audience is `sts.amazonaws.com`

**"AssumeRole token invalid"**
- OIDC provider thumbprint might be outdated
- Try recreating the provider with latest thumbprint

## Next Steps

Once OIDC is set up:
1. Push a test commit
2. Monitor workflow in GitHub Actions
3. Expand IAM permissions as your infrastructure grows
4. Consider using role sessions per environment (staging/production)

---

**Important:** Never commit AWS credentials. OIDC provides temporary, auto-rotating credentials.
