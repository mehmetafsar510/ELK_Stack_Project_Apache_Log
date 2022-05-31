# --- root/main.tf --- 

#Deploy Networking Resources

module "networking" {
  source           = "./modules/networking"
  vpc_cidr         = local.vpc_cidr
  private_sn_count = 5
  public_sn_count  = 5
  private_cidrs    = [for i in range(1, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  public_cidrs     = [for i in range(2, 255, 2) : cidrsubnet(local.vpc_cidr, 8, i)]
  max_subnets      = 5
  access_ip        = var.access_ip
  security_groups  = local.security_groups
  availability     = var.availability

}


module "loadbalancing" {
  source                  = "./modules/loadbalancing"
  public_sg               = module.networking.elastic_sg
  public_subnets          = module.networking.public_subnets
  tg_port1                = 9200
  tg_port2                = 5601
  tg_protocol             = "HTTP"
  vpc_id                  = module.networking.vpc_id
  elb_healthy_threshold   = 2
  elb_unhealthy_threshold = 2
  elb_timeout             = 3
  elb_interval            = 30
  listener_port           = 443
  listener_protocol       = "HTTPS"
  certificate_arn_elb     = module.route53.acm_arn
}

module "compute" {
  source                = "./modules/compute"
  elastic_sg            = module.networking.elastic_sg
  kibana_sg             = module.networking.kibana_sg
  logstash_sg           = module.networking.logstash_sg
  filebeat_sg           = module.networking.filebeat_sg
  public_subnets        = module.networking.public_subnets
  load_balancer_endpoint = module.loadbalancing.lb_endpoint
  instance_count        = 3
  instance_type_elastic = "t3a.large"
  instance_type_others  = "t2.small"
  vol_size              = "20"
  public_key_path       = "~/.ssh/the-doctor.pub"
  key_name              = "the-doctor"
  lb_target_group_arn1  = module.loadbalancing.lb_target_group_arn1
  lb_target_group_arn2  = module.loadbalancing.lb_target_group_arn2
  tg_port1              = 9200
  tg_port2              = 5601
  private_key_path      = "~/.ssh/the-doctor.pem"
}

module "route53" {
  source      = "./modules/route53"
  dns_name    = module.loadbalancing.lb_endpoint
  zone_id     = var.zone_id
  domain_name = var.domain_name
  cname       = var.cname
}