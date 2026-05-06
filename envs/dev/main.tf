provider "aws" {
  region = var.aws_region
}

module "networking" {
  source = "../../modules/networking"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.networking.vpc_id
  vpc_cidr     = module.networking.vpc_cidr

  depends_on = [module.networking]
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  aws_region         = var.aws_region
  aws_account_id     = var.aws_account_id
  cluster_version    = var.eks_cluster_version
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids

  depends_on = [module.networking, module.security]
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE 3: DATABASE
# ---------------------------------------------------------------------------------------------------------------------

module "database" {
  source = "../../modules/database"

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  database_subnet_ids           = module.networking.database_subnet_ids
  rds_security_group_id         = module.security.rds_security_group_id
  rds_proxy_security_group_id   = module.security.rds_proxy_security_group_id
  elasticache_security_group_id = module.security.elasticache_security_group_id

  depends_on = [module.networking, module.security]
}

