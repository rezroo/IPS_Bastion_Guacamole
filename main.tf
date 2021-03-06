# RDS module for the backend MySQL db.
module "rds" {
  source              = "git::https://github.com/Cimpress-MCP/terraform.git//rds"
  rds_name            = "${var.name}-rds"
  storage_size        = "10"
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "${var.rds_engine_ver}"
  instance_class      = "${var.rds_instance}"
  db_name             = "${var.db_name}"
  db_user             = "${var.db_user}"
  db_passwd           = "${var.db_pwd}"
  db_port             = "3306"
  skip_final_snapshot = "true"
  extra_tags          = "${var.extra_tags}"
  instance_sg_id      = "${aws_security_group.bastion_guac_instance_sg.id}"
  vpc_id              = "${var.vpc_id}"
  subnet_ids          = "${var.subnet_priv_ids}"
}

# S3+Replication module, for the bastion host config files
module "s3_repl" {
  source                  = "git::https://github.com/Cimpress-MCP/terraform.git//s3_replication"
  main_bucket_name        = "${var.name}-confs"
  replication_bucket_name = "${var.name}-confs-repl"
  replica_region          = "${var.replica_region}"
  access_roles_name       = ["${aws_iam_role.s3_role.name}"]
}

# S3 buckets for ALB/ELB Access Logs

module "s3_alb_web" {
  source      = "git::https://github.com/Cimpress-MCP/terraform.git//s3_elb_access_logs"
  bucket_name = "${var.name}-alb-https-logs"
}

module "s3_elb_ssh" {
  source      = "git::https://github.com/Cimpress-MCP/terraform.git//s3_elb_access_logs"
  bucket_name = "${var.name}-elb-ssh-logs"
}

# WAF_Setup Module

module "waf_setup" {
  source                    = "git::https://github.com/Cimpress-MCP/terraform.git//waf_setup"
  name                      = "${var.name}-WAF"
  accesslogbucket           = "${module.s3_alb_web.bucket_name}"
  sqlinjection              = "${var.sqlinjection}"
  xss                       = "${var.xss}"
  httpflood                 = "${var.httpflood}"
  scansprobe                = "${var.scansprobe}"
  reputationlists           = "${var.reputationlists}"
  badbot                    = "${var.badbot}"
  httprequeststhreshold     = "${var.httprequeststhreshold}"
  scansprobeserrorthreshold = "${var.scansprobeserrorthreshold}"
  wafblockperiod            = "${var.wafblockperiod}"
  albid                     = "${aws_lb.bastion_guac_alb.id}"
}
