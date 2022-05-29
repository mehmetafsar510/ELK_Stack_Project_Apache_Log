locals {
  vpc_cidr = "10.123.0.0/16"
}

locals {
  security_groups = {
    elastic = {
      name        = "elasticsearch_sg"
      description = "elasticsearch_sg"
      ingress = {
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        https = {
          from        = 443
          to          = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        http = {
          from        = 80
          to          = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        tg = {
          from        = 9200
          to          = 9300
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    kibana = {
      name        = "kibana_sg"
      description = "kibana_sg"
      ingress = {
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        tg2 = {
          from        = 5601
          to          = 5601
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    logstash = {
      name        = "logstash_sg"
      description = "logstash_sg"
      ingress = {
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        tg2 = {
          from        = 5044
          to          = 5044
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    filebeat = {
      name        = "filebeat_sg"
      description = "filebeat_sg"
      ingress = {
        open = {
          from        = 0
          to          = 0
          protocol    = -1
          cidr_blocks = [var.access_ip]
        }
        ssh = {
          from        = 22
          to          = 22
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}