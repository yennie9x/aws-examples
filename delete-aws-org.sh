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

# Step 1: Delete Organizational Units (OUs)
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
check_command "Get Root ID"
echo "Root ID: $ROOT_ID"

OUs=$(aws organizations list-organizational-units-for-parent --parent-id "$ROOT_ID" --query 'OrganizationalUnits[].Id' --output text)
for OU_ID in $OUs; do
  echo "Deleting OU: $OU_ID"
  ACCOUNTS=$(aws organizations list-accounts-for-parent --parent-id "$OU_ID" --query 'Accounts[].Id' --output text)
  for ACCOUNT_ID in $ACCOUNTS; do
    echo "Removing account: $ACCOUNT_ID from OU: $OU_ID"
    aws organizations remove-account-from-organization --account-id "$ACCOUNT_ID"
    check_command "Remove Account $ACCOUNT_ID"
  done
  aws organizations delete-organizational-unit --organizational-unit-id "$OU_ID"
  check_command "Delete OU $OU_ID"
  echo "Deleted OU: $OU_ID"
done

# Step 2: Close Member Accounts (Excluding Management Account)
MANAGEMENT_ACCOUNT_ID=$(aws organizations describe-organization --query 'Organization.MasterAccountId' --output text)
check_command "Get Management Account ID"
echo "Management Account ID: $MANAGEMENT_ACCOUNT_ID"

ACCOUNTS=$(aws organizations list-accounts --query 'Accounts[].Id' --output text)
for ACCOUNT_ID in $ACCOUNTS; do
  if [[ "$ACCOUNT_ID" == "$MANAGEMENT_ACCOUNT_ID" ]]; then
    echo "Skipping management account: $ACCOUNT_ID"
    continue
  fi
  echo "Closing account: $ACCOUNT_ID"
  aws organizations close-account --account-id "$ACCOUNT_ID"
  check_command "Close Account $ACCOUNT_ID"
  echo "Closed account: $ACCOUNT_ID"
done

# Step 3: Notify about Management Account Closure
if [[ -n "$MANAGEMENT_ACCOUNT_ID" ]]; then
  echo "The management account ($MANAGEMENT_ACCOUNT_ID) cannot be closed programmatically. Please follow the standard account closure process using root credentials."
fi

# Step 4: Delete AWS Organization
ORGANIZATION_EXISTS=$(aws organizations describe-organization 2>/dev/null || true)
if [[ -n "$ORGANIZATION_EXISTS" ]]; then
  echo "Deleting AWS Organization..."
  aws organizations delete-organization
  check_command "Delete Organization"
  echo "AWS Organization deleted."
else
  echo "No AWS Organization found."
fi

echo "AWS Organization cleanup complete."
