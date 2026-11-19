# AWS Three-Tier Architecture with Cross-Region Disaster Recovery

## Project Overview

This project demonstrates a three-tier web application architecture on AWS, provisioned using Terraform, with a cross-region Disaster Recovery (DR) approach.

The primary application runs in Mumbai (`ap-south-1`). A backup-and-restore DR environment is configured in Hyderabad (`ap-south-2`).

## Architecture

![AWS Three-Tier Architecture](docs/architecture.png)

- **Primary Region:** Mumbai (`ap-south-1`)
- **DR Region:** Hyderabad (`ap-south-2`)
- **Infrastructure as Code:** Terraform

### Primary Architecture Flow

```text
Internet
   |
Public Application Load Balancer
   |
Web EC2 Auto Scaling Group
   |
Internal Application Load Balancer
   |
Application EC2 Auto Scaling Group
   |
Amazon RDS MySQL
```

### Disaster Recovery Flow

```text
Mumbai Primary RDS
       |
Encrypted RDS Snapshot
       |
Cross-Region Snapshot Copy
       |
Hyderabad RDS Restore
       |
Private Database Connectivity Test
```

## AWS Services Used

| Category | Services |
|---|---|
| Networking | VPC, Subnets, Route Tables, Internet Gateway, NAT Gateway |
| Compute | EC2 |
| Auto Scaling | EC2 Auto Scaling Groups |
| Load Balancing | Public and Internal Application Load Balancers |
| Database | Amazon RDS MySQL |
| Security | IAM Roles, Security Groups, AWS KMS |
| Configuration and Secrets | AWS Systems Manager Parameter Store |
| Disaster Recovery | RDS Snapshots, Cross-Region Snapshot Copy |
| Infrastructure as Code | Terraform |
| Monitoring | Amazon CloudWatch |
| Notifications | Amazon SNS |
| CLI | AWS CLI |

## Primary Region — Mumbai

- VPC CIDR: `10.0.0.0/16`
- Public and private subnet architecture.
- Public Application Load Balancer.
- Web EC2 Auto Scaling Group with two instances.
- Internal Application Load Balancer.
- Application EC2 Auto Scaling Group with two instances.
- Amazon RDS MySQL in private database subnets.
- NAT Gateway for outbound connectivity.
- Database password stored in Systems Manager Parameter Store as SecureString.
- IAM instance roles for AWS access.

### Primary RDS Configuration

- Engine: MySQL 8.4
- Instance class: `db.t3.micro`
- Storage: 20 GiB gp3
- Encryption: Enabled
- Public access: Disabled
- Deployment: Single-AZ

## Disaster Recovery — Hyderabad

- DR Region: `ap-south-2`
- DR VPC CIDR: `10.1.0.0/16`
- Public, web, application, and database subnets.
- Internet Gateway and NAT Gateway.
- Public and internal Application Load Balancers.
- Web EC2 Auto Scaling Group with two instances.
- Application EC2 Auto Scaling Group with two instances.
- Restored private and encrypted RDS MySQL database.
- Regional SSM Parameter Store configuration.
- Security groups restrict database access to the application tier.

**DR strategy:** Backup and Restore with a pre-provisioned DR application environment.

### DR Database Recovery

1. Create a database snapshot from the Mumbai primary RDS instance.
2. Copy the encrypted snapshot to Hyderabad.
3. Restore an RDS instance from the copied snapshot.
4. Verify database authentication and connectivity from the DR application tier.

## Recovery Validation

The following tests were performed:

- Mumbai and Hyderabad application endpoints `/`, `/app/`, and `/db` returned HTTP 200.
- Web and application target groups reported healthy targets in both regions.
- Application instances successfully connected to their respective RDS databases.
- MySQL authentication and query execution were verified.
- Cross-region RDS snapshot copy and database restoration were tested.
- Manual endpoint switching from the Mumbai public ALB to the Hyderabad public ALB was tested.
- All three DR application endpoints returned HTTP 200 after the endpoint switch.

### RPO and RTO Test Notes

A controlled database test record was inserted into the Mumbai primary database. It was not present in the older Hyderabad restored snapshot.

This confirms that the restored snapshot did not include that later test record. It does not establish an exact measured RPO.

A manual endpoint-switch drill took approximately four seconds. This measures the client-side endpoint-switch exercise only, not a complete regional disaster recovery RTO.

**Limitations:** Automated failover and Route 53 failover are not implemented.

## Monitoring and Email Notifications

Amazon CloudWatch monitors the primary and DR environments.

Four alarms are configured in each region:

- Web target unhealthy hosts.
- Application target unhealthy hosts.
- RDS high CPU utilization.
- RDS low free storage.

Amazon SNS delivers email notifications through regional topics:

- Mumbai: `three-tier-primary-alerts`
- Hyderabad: `three-tier-dr-alerts`

Both email subscriptions were confirmed, and test notification emails were successfully received from both regions.

**Implementation note:** Mumbai CloudWatch alarm definitions are managed through Terraform. Hyderabad alarm configurations and SNS topic setup were performed using AWS CLI.

## Terraform Project Structure

```text
aws-three-tier-dr/
│
├── main.tf
├── dr.tf
├── providers.tf
├── variables.tf
├── locals.tf
├── monitoring.tf
├── .terraform.lock.hcl
├── .gitignore
├── docs/
│   └── architecture.png
├── screenshots/
└── README.md
```

## Deployment Commands

Run these commands from the Terraform project directory:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

Review the Terraform plan carefully before applying changes.

## Security Practices

- Use IAM roles instead of hardcoding AWS credentials.
- Store database passwords in SSM Parameter Store SecureString.
- Keep databases in private subnets.
- Restrict traffic using security groups.
- Encrypt RDS databases and snapshots.
- Do not commit credentials, `.tfvars` files, Terraform state files, or plan files to GitHub.

## Project Status

| Feature | Status |
|---|---|
| Mumbai three-tier architecture | Deployed and tested |
| Hyderabad DR network | Deployed |
| Hyderabad web and application tiers | Deployed and tested |
| Cross-region RDS snapshot copy | Tested |
| DR RDS restoration | Tested |
| Application-to-database connectivity | Tested in both regions |
| CloudWatch monitoring | Configured in both regions |
| SNS email notifications | Tested in both regions |
| Manual DR endpoint-switch drill | Tested |
| Automated regional failover | Not implemented |
| Route 53 failover | Not implemented |
| HTTPS and custom domain | Not implemented |
| Exact measured RPO and full regional RTO | Not established |

## Cost Considerations

AWS resources such as EC2, NAT Gateway, Application Load Balancers, RDS, snapshots, public IPv4 addresses, and cross-region data transfer may incur charges.

Review and clean up resources when they are no longer needed.

## Learning Outcomes

- AWS VPC and subnet design.
- Public and private network architecture.
- Three-tier application deployment.
- EC2 Auto Scaling and load balancing.
- Amazon RDS MySQL configuration.
- IAM and secure parameter management.
- Terraform infrastructure provisioning.
- Cross-region RDS snapshot copy and restore.
- Disaster Recovery validation.

## Author

Berlin

AWS | Terraform | DevOps | Cloud Infrastructure | Disaster Recovery