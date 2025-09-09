Custom VPC and Minimal Security Group

What I did

Created a custom VPC (10.0.0.0/16) instead of using the default VPC

Added a public subnet (10.0.1.0/24) in the available AZ

Created and attached an Internet Gateway (IGW)

Configured a public route table with 0.0.0.0/0 pointing to the IGW

Deployed a minimal Security Group (SG)

What I changed

Inbound rules allow only HTTP (80) and HTTPS (443)

SSH (22) access is intentionally not allowed (no open SSH to the internet)

Outbound rule allows all traffic (default)

Verification process

Confirmed all resources in the AWS Console (VPC, Subnet, IGW, Route Table, Security Group)

Captured screenshots of the resources and rules

Verified Terraform workflow with terraform apply and terraform destroy logs