
# GDPR & DORA-Compliant Infra with Terraform

## Deploy EU-sovereign AWS infrastructure with encryption and audit logging

This project deploys a secure, audited, and encrypted cloud perimeter within the AWS Europe (Frankfurt) region using Terraform. It translates European data privacy (GDPR), financial resilience (DORA) rules, and US CLOUD Act mitigations into automated Infrastructure as Code (IaC) guardrails.

---

## What It Does

The architecture establishes a secure perimeter in the `eu-central-1` (Frankfurt) region. It actively monitors all account management events and enforces an identity-based boundary. If an identity attempts to bypass compliance by provisioning services in non-EU zones (like the US), the regional restriction policy drops the request immediately.

---

## Why This Project Matters (The Motivation)

In the public cloud, resources can be deployed globally with a single click. However, for companies operating in the European Union, storing personal or financial data in non-EU countries is a major legal risk that can lead to catastrophic fines and compliance failures.

This project solves this problem by shifting compliance to the left. Instead of doing manual audits after a mistake happens, this infrastructure uses code to make compliance automatic, preventive, and impossible to bypass.

---

## The US CLOUD Act Conflict & Mitigation

### The Problem

The **US CLOUD Act** allows United States law enforcement to compel US-based technology companies (like AWS) to hand over data, **even if that data is physically stored on servers located in Europe** (such as Frankfurt). This creates a direct legal conflict with GDPR's strict data sovereignty rules.

### The Solution in this Repository

Mitigate this extraterritorial risk through two main files in this project:

1. **`kms.tf` (Cryptographic Sovereignty):** We do not use AWS default encryption. Instead, we generate our own **Customer Managed Keys (CMK)** with strict key policies. If AWS is ever forced to hand over the raw data bytes to a foreign government under the CLOUD Act, **they cannot decrypt it**, because the customer (the enterprise) holds absolute control over the cryptographic keys.

2. **`cloud-act-mitigation.tf`:** Establishes strict access boundaries and identity restrictions to ensure that only authorized EU-based entities can access the data, creating an extra layer of defense against unauthorized external requests.

---

## Regulatory Mapping: What This Lab Covers

Here are the exact regulatory frameworks and sections implemented in this code:

### 🇪🇺 General Data Protection Regulation (GDPR)

* **Data Residency (Sovereignty):** Implemented in `region-restriction.tf`. The region-lock policy physically blocks users and automation from launching databases or storage units outside the EU boundary, ensuring personal data never leaves sovereign borders.
* **Security of Processing (Data Encryption):** Implemented in `kms.tf`. Enforces strong data-at-rest encryption with mandatory key rotation controlled entirely by the organization.
* **Accountability & Traceability (Data Minimization):** Implemented via `audit.tf` and `storage.tf`. Generates a complete record of who accessed or modified data, satisfying the requirement to detect, trace, and report potential security breaches instantly.

### Digital Operational Resilience Act (DORA)

* **Pillar 1 (ICT Risk Management):** Restricts the operational blast radius by preventing accidental or unauthorized infrastructure deployments in unapproved global regions.
`
* **Pillar 2 (ICT Incident Reporting & Audit Trails):** Implemented via `audit.tf`, `storage.tf` and `monitoring.tf`. We orchestrate AWS CloudTrail to log 100% of administrative events into an immutable, tamper-proof S3 bucket with Object Lock (Compliance Mode). Concurrently, CloudWatch Metric Filters actively scan these logs for unauthorized API errors (`AccessDenied`), automatically triggering real-time CloudWatch Alarms and SNS notifications to ensure instant incident detection and rapid compliance reporting.

* **Pillar 4 (Third-Party Risk Management / Cloud Vendor Control):** Implemented via `kms.tf` and cloud-act-mitigation.tf. It establishes enterprise-managed guardrails to control cloud vendor exposure, ensuring that third-party infrastructure providers cannot access or compromise sensitive financial data.

---

## Technologies Used

- **Terraform** - Infrastructure as Code to provision and manage cloud security controls
- **AWS KMS** - Cryptographic key management with automated rotation policies
- **AWS CloudTrail** - Continuous account auditing and governance logging
- **AWS S3** - Hardened storage featuring object-level immutability (Object Lock)
- **AWS IAM** - Fine-grained access control and geographic region enforcement
- **AWS CloudWatch & SNS** - Real-time incident tracking, pattern filtering, and alerting

---

## Project Structure

Following cloud development best practices, the Terraform configuration is modularized to split specific compliance services across dedicated files:

```text
eu-compliance-infra/
├── terraform.tf        # Core Terraform settings and provider requirements
├── variables.tf        # Dynamic naming, resource tags, and allowed regions (no hardcoding)
├── kms.tf              # KMS Customer Managed Keys and rotation definitions
├── storage.tf          # Hardened S3 bucket with Object Lock (WORM) and Lifecycle Rules (GDPR)
├── audit.tf            # CloudTrail orchestration linked to secure storage
├── monitoring.tf       # CloudWatch Metric Filters, Alarms, and SNS Topics for incident alerts (DORA)
├── region-restriction.tf # IAM policy with explicit Deny logic for region lockdown
├── cloud-act-mitigation.tf # Advanced policies to safeguard data from foreign requests
├── upload-encrypted.sh # Bash automation script for secure file uploads
└── outputs.tf          # Cross-cutting resource identifiers and policy ARNs

## Security Practices

This project applies production-grade cloud compliance and data sovereignty standards:

- **Data Sovereignty (GDPR):** The infrastructure uses a conditional region whitelist to instantly block resource deployment and data movement outside the EU.
- **Log Immutability (DORA):** Audit logs are secured in an S3 bucket running in Compliance Mode. This creates a Write-Once-Read-Many (WORM) pattern, preventing modification or deletion by any user.
- **Cryptographic Ownership:** Enforces data-at-rest encryption via Customer Managed Keys (CMK) with `enable_key_rotation = true` to stay compliant with financial audit rules.
- **Tamper Detection:** CloudTrail log file integrity validation is activated mathematically to guarantee the authenticity of the audit trail.
- **Data Lifecycle Management (GDPR Data Minimization):** Implements an automated S3 Lifecycle policy that transitions logs to S3 Glacier after 30 days and enforces permanent deletion at 90 days, adhering strictly to the principle of data minimization.
- **Continuous Monitoring & Alerting (DORA Compliance):** Utilizes CloudWatch Metric Filters to scan logs for `AccessDenied` or `UnauthorizedOperation` API errors in real-time, instantly triggering security alarms and AWS SNS notifications upon incident detection.


## How to Run

### Prerequisites

- AWS CLI configured with administrative credentials
- Terraform installed

### Steps

1. Initialize the Terraform providers and working directory:

```bash
terraform init
```

2. Run a structural dry-run to preview infrastructure changes:

```bash
terraform plan
```

3. Provision the compliant environment in your AWS account:

```bash
terraform apply -auto-approve
```

4. Activate the geographic restriction on your active operating user:

```bash
# Extract your current IAM username
CURRENT_USER=$(aws iam get-user --query "User.UserName" --output text)

# Attach the regional restriction policy using Terraform outputs
aws iam attach-user-policy --user-name $CURRENT_USER --policy-arn $(terraform output -raw region_restriction_policy_arn)
```

5. Clean up (Be aware that Object Locked logs cannot be deleted instantly due to compliance retention rules):

```bash
terraform destroy
```

---

## Compliance Verification

To verify that the data residency guardrail is working, attempt to create an S3 storage bucket outside the European Union boundary (e.g., in us-east-1):

```bash
$ aws s3api create-bucket --bucket test-eu-restriction-check --region us-east-1
```

Expected result:

```bash
An error occurred (AccessDenied) when calling the CreateBucket operation: User: arn:aws:iam::816973614337:user/GDPR_DORA is not authorized to perform: s3:CreateBucket on resource: "arn:aws:s3:::test-eu-restriction-check" with an explicit deny in an identity-based policy
```

*Analysis: The policy in `region-restriction.tf` successfully intercepted the unauthorized API call, proving our data residency boundary is working perfectly.*

---

## Architecture

```text
[User Action] ──> [AWS API Gateway]
                          │
                          ▼
             [region-restriction.tf] 
         (Enforces Whitelist Region Check)
         /                                 \
  (Outside EU)                        (Inside EU)
      /                                     \
     ▼                                       ▼
[AccessDenied Error]               [Operation Allowed]
                                            │
                                            ▼
                                   [CloudTrail Tracking] ──> [kms.tf] (SSE-KMS Encryption)
                                            │
                      ┌─────────────────────┴─────────────────────┐
                      ▼                                           ▼
             [CloudWatch Logs]                             [storage.tf]
         (Metric Filters & Alarms)               (S3 Object Lock - WORM Layer)
                      │                                           │
                      ▼                                           ▼
          [SNS Security Alert]                        [Data Lifecycle Policy]
       (Instant Incident Notification)             (30d Glacier -> 90d Purge)
```

## Author

Built as part of my Cloud Engineering self-learning path.
