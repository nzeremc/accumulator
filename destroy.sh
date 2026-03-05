#!/bin/bash

# DOCMP Infrastructure Destroy Script (Local)
# This script will destroy all AWS resources created by Terraform

set -e  # Exit on error

echo "=========================================="
echo "DOCMP Infrastructure Destroy Script"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will destroy ALL infrastructure!"
echo "⚠️  This action cannot be undone!"
echo ""
echo "Resources that will be destroyed:"
echo "  - VPC and all networking components"
echo "  - 2x PostgreSQL RDS instances"
echo "  - MSK Kafka cluster"
echo "  - Redis cluster"
echo "  - ECS cluster and services"
echo "  - Application Load Balancer"
echo "  - S3 bucket (with all data)"
echo "  - ECR repositories (with all images)"
echo "  - Secrets Manager secrets"
echo "  - IAM roles and policies"
echo ""

# Ask for confirmation
read -p "Are you sure you want to destroy everything? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Destroy cancelled."
    exit 0
fi

echo ""
read -p "Type the project name 'docmp' to confirm: " PROJECT_NAME

if [ "$PROJECT_NAME" != "docmp" ]; then
    echo "Project name doesn't match. Destroy cancelled."
    exit 0
fi

echo ""
echo "Starting destroy process..."
echo ""

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "Initializing Terraform..."
    terraform init
fi

# Run terraform destroy
echo ""
echo "Running terraform destroy..."
echo ""

terraform destroy -var-file="terraform.tfvars"

echo ""
echo "=========================================="
echo "✅ Infrastructure destroyed successfully!"
echo "=========================================="
echo ""
echo "Note: The following may need manual cleanup:"
echo "  - S3 backend bucket (if you want to remove state)"
echo "  - CloudWatch log groups (may have retention)"
echo "  - Secrets in Secrets Manager (have recovery window)"
echo ""

# Made with Bob
