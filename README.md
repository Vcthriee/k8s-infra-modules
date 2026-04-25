# Ecommerce Infrastructure — Terraform

AWS infrastructure for the ecommerce platform.
Provisions a production-grade EKS cluster with networking and security.

## Architecture Diagram

![Architecture](architecture/architecture-diagram.svg)

## Architecture
AWS Account (af-south-1)
├── VPC
│   ├── Public Subnets  — ALB, NAT Gateways
│   └── Private Subnets — EKS nodes
├── EKS Cluster
│   ├── Managed Node Group
│   ├── OIDC Provider
│   └── EBS CSI Driver
├── Security Groups
│   ├── ALB
│   └── EKS Nodes
└── VPC Endpoints
├── S3 Gateway (free — eliminates NAT Gateway charges)
└── DynamoDB Gateway (free)

## Modules Used

| Module | Purpose |
|--------|---------|
| `networking` | VPC, subnets, gateways, route tables, VPC endpoints |
| `security` | Security groups for ALB and EKS nodes |
| `eks` | EKS cluster, node groups, IAM roles, OIDC, addons |

## Modules Available but Not Deployed

| Module | Purpose |
|--------|---------|
| `database` | RDS PostgreSQL, ElastiCache Redis, RDS Proxy |
| `observability` | Prometheus, Grafana, Loki |
| `platform_services` | ArgoCD, cert-manager, external-secrets, Velero |
| `security_platform` | Cilium, Falco, Kyverno, network policies |

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate permissions
- S3 bucket for Terraform state (see `envs/dev/backend.tf`)

## Quick Start

```bash
# Navigate to dev environment
cd envs/dev

# Initialise Terraform
terraform init

# Preview changes
terraform plan

# Apply
terraform apply
```

## Environment Structure
envs/
└── dev/
├── backend.tf      # S3 remote state config
├── main.tf         # Module calls
├── variables.tf    # Input variable declarations
├── terraform.tfvars # Variable values
└── outputs.tf      # Output values

## Key Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `region` | AWS region | `af-south-1` |
| `environment` | Environment name | `dev` |
| `cluster_name` | EKS cluster name | `ecommerce-dev` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |

## Outputs

After `terraform apply`, key outputs include:

- `cluster_endpoint` — EKS API server endpoint
- `cluster_name` — EKS cluster name
- `vpc_id` — VPC ID

## Configure kubectl after deploy

```bash
aws eks update-kubeconfig \
  --region af-south-1 \
  --name <your-cluster-name>
```

## Remote State

State is stored in S3 with DynamoDB locking.
See `envs/dev/backend.tf` for bucket and table names.

## Cost Notes

- VPC Gateway Endpoints for S3 and DynamoDB are free
  and eliminate NAT Gateway data processing charges
- EKS control plane: ~$72/month
- NAT Gateway: ~$32/month base + data transfer
- EKS nodes: depends on instance type and count

## Destroy

```bash
cd envs/dev
terraform destroy
```

> ⚠️ This will delete all infrastructure including the EKS cluster.