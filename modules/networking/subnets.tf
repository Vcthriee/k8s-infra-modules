# Public subnets - ALB and NAT gateways live here
# map_public_ip_on_launch = true required for NAT gateway ENIs
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    # Required by AWS Load Balancer Controller to discover public subnets
    "kubernetes.io/role/elb" = "1"
    Type                     = "public"
  }
}

# Private subnets - EKS nodes and pods run here
# Karpenter discovers these via tag to launch nodes
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + length(var.availability_zones))
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-private-${var.availability_zones[count.index]}"
    # Required by AWS Load Balancer Controller for internal ALBs
    "kubernetes.io/role/internal-elb" = "1"
    # Required by Karpenter to discover subnet placement options
    "karpenter.sh/discovery" = "${var.project_name}-${var.environment}"
    Type = "private"
  }
}

# Database subnets - RDS and ElastiCache live here
# Isolated from EKS nodes for security, accessed via security group rules only
resource "aws_subnet" "database" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 2 * length(var.availability_zones))
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-${var.environment}-database-${var.availability_zones[count.index]}"
    Type = "database"
  }
}