# Example: OIDC Provider and Federated Role (Terraform 0.11 Style)
# This demonstrates how ${var.oidc_provider_arn} and ${var.oidc_provider_name} work

# OPTIONAL: Create an OIDC Identity Provider (if you don't have one)
# Uncomment this block if you need to create a new OIDC provider
#
# resource "aws_iam_openid_connect_provider" "example" {
#   url = "https://oidc.eks.us-east-1.amazonaws.com/id/EXAMPLE"
#
#   client_id_list = [
#     "sts.amazonaws.com",
#   ]
#
#   thumbprint_list = [
#     "9e99a48a9960b14926bb7f3b02e22da2b0ab7280",
#   ]
# }

# IAM Role with Federated Identity Provider (OLD TERRAFORM 0.11 STYLE)
resource "aws_iam_role" "federated_role" {
  name = "${var.project_name}-federated-role"

  # THIS IS THE OLD STYLE SYNTAX YOU ASKED ABOUT:
  # - ${var.oidc_provider_arn} replaces the Federated value
  # - ${var.oidc_provider_name} is used in the Condition key
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "${var.oidc_provider_arn}"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringLike": {
            "${var.oidc_provider_name}:sub": "system:serviceaccount:*:*"
          }
        }
      }
    ]
  }
  EOF

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-federated-role"
    }
  )
}

# Attach policies to the federated role
resource "aws_iam_role_policy" "federated_role_policy" {
  name = "${var.project_name}-federated-policy"
  role = aws_iam_role.federated_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource": [
          "${var.s3_bucket_arn}",
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  }
  EOF
}

# ============================================================================
# EXPLANATION OF OLD TERRAFORM 0.11 SYNTAX:
# ============================================================================
#
# 1. "${var.oidc_provider_arn}" in Federated field:
#    - This is string interpolation using ${...}
#    - It takes the value from variable oidc_provider_arn
#    - Example value: "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/ABC123"
#    - This tells AWS WHICH identity provider to trust
#
# 2. "${var.oidc_provider_name}:sub" in Condition:
#    - This creates a dynamic condition key
#    - Example: if oidc_provider_name = "oidc.eks.us-east-1.amazonaws.com/id/ABC123"
#    - It becomes: "oidc.eks.us-east-1.amazonaws.com/id/ABC123:sub"
#    - The :sub is the claim name from the OIDC token
#    - This checks WHAT is requesting access (which service account)
#
# 3. How they work together:
#    Step 1: Service (like Kubernetes pod) requests AWS credentials
#    Step 2: AWS checks if the request comes from the Federated provider (using arn)
#    Step 3: AWS validates the token claims match the Condition (using provider name)
#    Step 4: If both match, AWS grants temporary credentials
#
# 4. Common use cases:
#    - EKS pods accessing AWS services (Kubernetes service accounts)
#    - GitHub Actions workflows deploying to AWS
#    - GitLab CI/CD pipelines
#    - Any external identity provider using OIDC/SAML
#
# 5. Why use variables instead of hardcoded values:
#    - Reusability: Same role template for multiple providers
#    - Flexibility: Easy to change provider without editing policy
#    - Security: Provider details can be stored in tfvars or secrets