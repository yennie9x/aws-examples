### Add permssion
chmod +x *

### Run setup.sh
./setup.sh


### References
1. Setup aws: https://never-stop-learning.de/setup-github-codespace-for-aws-development/
2. Goodnote setup ORGs



# Understanding AWS ARNs (Amazon Resource Names)

## What is an ARN?
An **ARN** (Amazon Resource Name) is a unique identifier used to reference AWS resources. It provides a way to fully specify a resource across AWS services in a consistent format.

---

## ARN Format
The general structure of an ARN is:
```
arn:partition:service:region:account-id:resource
```
### Components:
- **`partition`**: The AWS partition (e.g., `aws` for standard AWS regions, `aws-us-gov` for AWS GovCloud, or `aws-cn` for China).
- **`service`**: The AWS service (e.g., `s3`, `ec2`, `iam`).
- **`region`**: The AWS region where the resource resides (e.g., `us-east-1`). This can be blank for global services like IAM.
- **`account-id`**: The AWS account ID of the resource owner.
- **`resource`**: The specific resource being identified, often including resource type or name.

---

## Examples of ARNs

### 1. **S3 Bucket**:
```
arn:aws:s3:::example-bucket
```

### 2. **EC2 Instance**:
```
arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0
```

### 3. **IAM Role**:
```
arn:aws:iam::123456789012:role/MyRole
```

### 4. **DynamoDB Table**:
```
arn:aws:dynamodb:us-west-2:123456789012:table/MyTable
```

---

## How ARNs Are Used

1. **IAM Policies**:
   ARNs are used to specify which resources a policy applies to.
   
2. **Service Access**:
   Referencing specific resources for operations in services like Lambda, API Gateway, and more.
   
3. **Auditing**:
   Used in AWS CloudTrail logs to identify resource interactions.

---

## Benefits of Using ARNs
- Ensure precise targeting of intended AWS resources.
- Provide a standard way to identify resources across various services and accounts.
- Enable programmatic management of resources via tools like AWS CLI and SDKs.

---

For more details, refer to the [AWS Documentation on ARNs](https://docs.aws.amazon.com/general/latest/gr/aws-arns-and-namespaces.html).

