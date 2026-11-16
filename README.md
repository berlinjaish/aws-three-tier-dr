\# AWS Three-Tier Architecture with Cross-Region Disaster Recovery



\## Project Overview



This project focuses on designing and implementing a secure, scalable, and highly available three-tier web application architecture on Amazon Web Services (AWS), provisioned entirely using Terraform.



The architecture separates the application into Presentation, Application, and Database layers. It also incorporates a cross-region Disaster Recovery strategy to improve business continuity and data protection.



## Architecture


![AWS Three-Tier Architecture with Disaster Recovery](docs/architecture.png)



\*\*Primary Region:\*\* Mumbai (`ap-south-1`)



\*\*Disaster Recovery Region:\*\* Hyderabad (`ap-south-2`)



Architecture diagram: `docs/architecture.png`



\## AWS Services Used



| Category | AWS Services |

|---|---|

| Networking | VPC, Subnets, Route Tables, Internet Gateway, NAT Gateway |

| Compute | EC2, Auto Scaling |

| Load Balancing | Application Load Balancer |

| Storage | Amazon S3, EBS |

| Database | Amazon RDS MySQL |

| Content Delivery | CloudFront |

| Security | IAM, Security Groups |

| Monitoring | CloudWatch |

| Disaster Recovery | AWS Backup, S3 Cross-Region Replication, RDS Snapshots, EC2 AMIs |



\## Three-Tier Architecture



\### 1. Presentation Layer

\- Amazon CloudFront

\- Amazon S3

\- Public Application Load Balancer

\- EC2 Web Servers

\- Auto Scaling Group



\### 2. Application Layer

\- Internal Application Load Balancer

\- EC2 Application Servers

\- Auto Scaling Group

\- Private Subnets



\### 3. Database Layer

\- Amazon RDS MySQL

\- Private Database Subnets

\- Multi-AZ database deployment



\## Disaster Recovery Strategy



The project uses Mumbai as the primary region and Hyderabad as the secondary recovery region.



Planned recovery mechanisms:



\- Amazon S3 Cross-Region Replication

\- RDS automated backups and cross-region snapshots

\- EC2 AMI backups

\- EBS snapshots

\- Secondary VPC infrastructure

\- Application restoration and recovery testing



Initial recovery approach: \*\*Backup and Restore\*\*.



\## Infrastructure as Code



Terraform is used to provision and manage AWS infrastructure.



The project uses reusable Terraform modules to organize infrastructure components and separate primary and disaster recovery configurations.



\## Project Structure



```text

aws-three-tier-dr/

│

├── modules/

│   ├── vpc/

│   ├── security-groups/

│   ├── alb/

│   ├── ec2/

│   ├── autoscaling/

│   ├── rds/

│   ├── s3/

│   └── cloudfront/

│

├── environments/

│   ├── dev/

│   └── dr/

│

├── screenshots/

├── docs/

├── README.md

└── .gitignore

```



\## Project Status



\*\*Status: In Progress\*\*



Implementation will be completed in phases:



\- \[ ] Terraform configuration

\- \[ ] Primary VPC and networking

\- \[ ] Presentation layer

\- \[ ] Application layer

\- \[ ] Database layer

\- \[ ] CloudFront and S3

\- \[ ] Disaster Recovery infrastructure

\- \[ ] Cross-region backup configuration

\- \[ ] Recovery testing

\- \[ ] Monitoring and documentation



\## Domain Configuration



A custom domain and HTTPS configuration using Route 53 and AWS Certificate Manager will be considered in a later phase. Initially, AWS-generated service endpoints will be used.



\## Security Considerations



\- Least-privilege IAM permissions

\- Network segmentation using public and private subnets

\- Security groups restricting communication between tiers

\- Database isolation

\- Secure Terraform state management

\- No AWS credentials or sensitive state files committed to GitHub



\## Screenshots



Implementation screenshots and testing evidence will be added as the project progresses.



\## Learning Outcomes



\- AWS networking and infrastructure architecture

\- Three-tier application design

\- Terraform infrastructure provisioning

\- High availability using multiple Availability Zones

\- Cross-region Disaster Recovery

\- AWS backup and recovery mechanisms

\- Infrastructure security and monitoring



\## Author



Berlin



AWS | Terraform | Cloud Infrastructure | Disaster Recovery

