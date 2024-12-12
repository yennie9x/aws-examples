#!/bin/bash

# Exit on any error
set -e

# Function to check if AWS CLI command succeeded
check_command() {
  if [ $? -ne 0 ]; then
    echo "Error: $1 failed. Exiting."
    exit 1
  fi
}

# Step 1: Create AWS Organization
ORGANIZATION_EXISTS=$(aws organizations describe-organization 2>/dev/null || true)
if [[ -z "$ORGANIZATION_EXISTS" ]]; then
  echo "Creating AWS Organization..."
  aws organizations create-organization --feature-set ALL
  check_command "Create Organization"
  echo "AWS Organization created."
else
  echo "AWS Organization already exists."
fi

# Step 2: Get the Root ID
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
check_command "Get Root ID"
echo "Root ID: $ROOT_ID"

# Step 3: Create Organizational Units (OUs)
OUs=( "Production" "Development" "Shared Services" )
OU_IDS=()
for OU in "${OUs[@]}"; do
  echo "Creating OU: $OU"
  OU_ID=$(aws organizations create-organizational-unit \
    --parent-id "$ROOT_ID" \
    --name "$OU" \
    --query 'OrganizationalUnit.Id' \
    --output text)
  check_command "Create OU $OU"
  echo "$OU created with ID: $OU_ID"
  OU_IDS+=("$OU_ID")
done

# Step 4: Create Accounts and Assign to OUs
# Define accounts for each OU using a different approach
ACCOUNTS_PRODUCTION=( "Prod-Web" "Prod-Database" "Prod-Analytics" )
ACCOUNTS_DEVELOPMENT=( "Dev-Web" "Dev-Database" "Dev-Testing" )
ACCOUNTS_SHARED_SERVICES=( "Logging" "Security" "Networking" )

ACCOUNTS=(
  "Production:${ACCOUNTS_PRODUCTION[*]}"
  "Development:${ACCOUNTS_DEVELOPMENT[*]}"
  "Shared Services:${ACCOUNTS_SHARED_SERVICES[*]}"
)

for i in "${!OUs[@]}"; do
  OU_NAME="${OUs[$i]}"
  OU_ID="${OU_IDS[$i]}"

  for ACCOUNT_GROUP in "${ACCOUNTS[@]}"; do
    IFS=':' read -r OU_KEY ACCOUNT_LIST <<< "$ACCOUNT_GROUP"
    if [[ "$OU_NAME" == "$OU_KEY" ]]; then
      for ACCOUNT_NAME in $ACCOUNT_LIST; do
        echo "Creating account: $ACCOUNT_NAME in OU: $OU_NAME"
        CREATE_ACCOUNT_ID=$(aws organizations create-account \
          --email "${ACCOUNT_NAME,,}@example.com" \
          --account-name "$ACCOUNT_NAME" \
          --query 'CreateAccountStatus.Id' \
          --output text)
        check_command "Create Account $ACCOUNT_NAME"

        echo "Waiting for account creation to complete..."
        while true; do
          ACCOUNT_STATUS=$(aws organizations describe-create-account-status \
            --create-account-request-id "$CREATE_ACCOUNT_ID" \
            --query 'CreateAccountStatus.State' \
            --output text)
          if [[ "$ACCOUNT_STATUS" == "SUCCEEDED" ]]; then
            echo "Account $ACCOUNT_NAME created successfully."
            break
          elif [[ "$ACCOUNT_STATUS" == "FAILED" ]]; then
            echo "Account $ACCOUNT_NAME creation failed."
            exit 1
          else
            echo "Account $ACCOUNT_NAME creation is still in progress..."
            sleep 10
          fi
        done

        # Move the account to the appropriate OU
        ACCOUNT_ID=$(aws organizations describe-create-account-status \
          --create-account-request-id "$CREATE_ACCOUNT_ID" \
          --query 'CreateAccountStatus.AccountId' \
          --output text)
        aws organizations move-account \
          --account-id "$ACCOUNT_ID" \
          --source-parent-id "$ROOT_ID" \
          --destination-parent-id "$OU_ID"
        check_command "Move Account $ACCOUNT_NAME to OU $OU_NAME"
        echo "Account $ACCOUNT_NAME moved to $OU_NAME."
      done
    fi
  done
done

echo "AWS Organization setup complete."


# Does it cost money when create organization?
# ChatGPT said:
# No, creating an AWS Organization itself does not incur any additional charges. AWS Organizations is a free service provided to help manage multiple AWS accounts centrally.
# However, here are some cost-related considerations:
# AWS Account Usage Costs: Each AWS account under your organization can incur costs based on the resources and services used within those accounts. These costs are billed to the management account (formerly called the master account).
# Data Transfer: If you use multiple AWS accounts to share resources, inter-account data transfers may result in costs.
# Consolidated Billing: AWS Organizations enables consolidated billing, allowing you to manage the costs of all accounts under the organization. This feature itself is free but may simplify cost management.
# Third-party Services: If third-party integrations or services are used in conjunction with AWS Organizations, those services may incur charges.
# To ensure you don't face unexpected costs:

# Use AWS Budgets to set up alerts for account spending.
# Regularly monitor billing and usage in the AWS Billing and Cost Management console.
# Let me know if you need further clarification!


