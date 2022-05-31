data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}
#elasticsearch
resource "aws_key_pair" "elastic_ssh_key" {
  key_name=var.key_name
  public_key= file(var.public_key_path)
}
resource "aws_instance" "elastic_nodes" {
  count         = var.instance_count
  ami                    = data.aws_ami.server_ami.id #"ami-04d29b6f966df1537"
  instance_type          = var.instance_type_elastic
  subnet_id              = var.public_subnets[count.index]
  vpc_security_group_ids = [var.elastic_sg]
  key_name               = aws_key_pair.elastic_ssh_key.key_name
  associate_public_ip_address = true
  tags = {
    Name = "elasticsearch_${count.index}"
  }
}
data "template_file" "init_elasticsearch" {
  depends_on = [ 
    aws_instance.elastic_nodes
  ]
  count         = var.instance_count
  template = file("${path.root}/elasticsearch_config.tpl")
  vars = {
    cluster_name = "cluster1"
    node_name = "node_${count.index}"
    node = aws_instance.elastic_nodes[count.index].private_ip
    node1 = aws_instance.elastic_nodes[0].private_ip
    node2 = aws_instance.elastic_nodes[1].private_ip
    node3 = aws_instance.elastic_nodes[2].private_ip
  }
}
resource "null_resource" "move_elasticsearch_file" {
  count         = var.instance_count
  connection {
     type = "ssh"
     user = "ec2-user"
     private_key = file(var.private_key_path)
     host= aws_instance.elastic_nodes[count.index].public_ip
  } 
  provisioner "file" {
    content = data.template_file.init_elasticsearch[count.index].rendered
    destination = "elasticsearch.yml"
  }
}
resource "null_resource" "start_es" {
  depends_on = [ 
    null_resource.move_elasticsearch_file
  ]
  count         = var.instance_count
  connection {
     type = "ssh"
     user = "ec2-user"
     private_key = file(var.private_key_path)
     host= aws_instance.elastic_nodes[count.index].public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "sudo yum update -y",
      "sudo rpm -i https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.2.2-x86_64.rpm",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable elasticsearch.service",
      "sudo sed -i 's@-Xms1g@-Xms${aws_instance.elastic_nodes[count.index].root_block_device[0].volume_size/2}g@g' /etc/elasticsearch/jvm.options",
      "sudo sed -i 's@-Xmx1g@-Xmx${aws_instance.elastic_nodes[count.index].root_block_device[0].volume_size/2}g@g' /etc/elasticsearch/jvm.options",
      "sudo rm /etc/elasticsearch/elasticsearch.yml",
      "sudo cp elasticsearch.yml /etc/elasticsearch/",
      "sudo systemctl start elasticsearch.service"
    ]
  }
}
#kibana setup
resource "aws_instance" "kibana" {
  depends_on = [ 
    null_resource.start_es
   ]
  count         = 1
  ami                    = data.aws_ami.server_ami.id
  instance_type          = var.instance_type_others
  subnet_id              = var.public_subnets[count.index]
  vpc_security_group_ids = [var.kibana_sg]
  key_name               = aws_key_pair.elastic_ssh_key.key_name
  associate_public_ip_address = true
  tags = {
    Name = "kibana"
  }
}
data "template_file" "init_kibana" {
  depends_on = [ 
    aws_instance.kibana
  ]
  template = file("${path.root}/kibana_config.tpl")
  vars = {
    elasticsearch = aws_instance.elastic_nodes[0].public_ip
    elasticsearch1 = aws_instance.elastic_nodes[1].public_ip
    elasticsearch2 = aws_instance.elastic_nodes[2].public_ip
  }
}
resource "null_resource" "move_kibana_file" {
  depends_on = [ 
    aws_instance.kibana
   ]
  count         = 1
  connection {
     type = "ssh"
     user = "ec2-user"
     private_key = file(var.private_key_path)
     host= aws_instance.kibana[count.index].public_ip
  } 
  provisioner "file" {
    content = data.template_file.init_kibana.rendered
    destination = "kibana.yml"
  }
}

resource "null_resource" "install_kibana" {
  depends_on = [ 
      aws_instance.kibana
   ]
  count         = 1
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file(var.private_key_path)
    host= aws_instance.kibana[count.index].public_ip
  } 
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo rpm -i https://artifacts.elastic.co/downloads/kibana/kibana-8.2.2-x86_64.rpm",
      "sudo rm /etc/kibana/kibana.yml",
      "sudo cp kibana.yml /etc/kibana/",
      "sudo systemctl start kibana"
    ]
  }
}

#logstash

resource "aws_instance" "logstash" {
  depends_on = [ 
    null_resource.install_kibana
   ]
  count                  = 1
  ami                    = data.aws_ami.server_ami.id
  instance_type          = var.instance_type_others
  subnet_id = var.public_subnets[count.index]
  vpc_security_group_ids = [var.logstash_sg]
  key_name               = aws_key_pair.elastic_ssh_key.key_name
  associate_public_ip_address = true
  tags = {
    Name = "logstash"
  }
}
data "template_file" "init_logstash" {
  depends_on = [ 
    aws_instance.logstash
  ]
  template = file("${path.root}/logstash_config.tpl")
  vars = {
    elasticsearch = aws_instance.elastic_nodes[0].public_ip
    elasticsearch1 = aws_instance.elastic_nodes[1].public_ip
    elasticsearch2 = aws_instance.elastic_nodes[2].public_ip
  }
}
resource "null_resource" "move_logstash_file" {
  depends_on = [ 
    aws_instance.logstash
   ]
  count         = 1
  connection {
     type = "ssh"
     user = "ec2-user"
     private_key = file(var.private_key_path)
     host= aws_instance.logstash[count.index].public_ip
  } 
  provisioner "file" {
    content = data.template_file.init_logstash.rendered
    destination = "logstash.conf"
  }
}

resource "null_resource" "install_logstash" {
  depends_on = [ 
      aws_instance.logstash
   ]
  count         = 1
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file(var.private_key_path)
    host= aws_instance.logstash[count.index].public_ip
  } 
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y && sudo yum install java-1.8.0-openjdk -y",
      "sudo rpm -i https://artifacts.elastic.co/downloads/logstash/logstash-7.5.1.rpm",
      "sudo cp logstash.conf /etc/logstash/conf.d/logstash.conf",
      "sudo systemctl start logstash.service"
    ]
  }
}


 #filebeat

resource "aws_instance" "filebeat" {
  depends_on = [ 
    null_resource.install_logstash
   ]
  count                  = 1
  ami                    = data.aws_ami.server_ami.id
  instance_type          = var.instance_type_others
  subnet_id = var.public_subnets[count.index]
  vpc_security_group_ids = [var.filebeat_sg]
  key_name               = aws_key_pair.elastic_ssh_key.key_name
  associate_public_ip_address = true
  tags = {
    Name = "filebeat"
  }
}

resource "null_resource" "move_filebeat_file" {
  depends_on = [ 
    aws_instance.filebeat
   ]
  count         = 1
  connection {
     type = "ssh"
     user = "ec2-user"
     private_key = file(var.private_key_path)
     host= aws_instance.filebeat[count.index].public_ip
  } 
  provisioner "file" {
    source = "${path.root}/filebeat.yml"
    destination = "filebeat.yml"
  }
}

resource "null_resource" "install_filebeat" {
  depends_on = [ 
    null_resource.move_filebeat_file
   ]
  count         = 1
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file(var.private_key_path)
    host= aws_instance.filebeat[count.index].public_ip
  } 
  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo rpm -i https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.5.1-x86_64.rpm",
      "sudo sed -i 's@kibana_ip@${aws_instance.kibana[count.index].public_ip}@g' filebeat.yml",
      "sudo sed -i 's@logstash_ip@${aws_instance.logstash[count.index].public_ip}@g' filebeat.yml",
      "sudo rm /etc/filebeat/filebeat.yml",
      "sudo cp filebeat.yml /etc/filebeat/",
      "sudo systemctl start filebeat.service"
    ]
  }
}

resource "aws_lb_target_group_attachment" "mtc_tg_attach1" {
  count            = var.instance_count
  target_group_arn = var.lb_target_group_arn1
  target_id        = aws_instance.elastic_nodes[count.index].id
  port             = var.tg_port1
}

resource "aws_lb_target_group_attachment" "mtc_tg_attach2" {
  count            = "1"
  target_group_arn = var.lb_target_group_arn2
  target_id        = aws_instance.kibana[count.index].id
  port             = var.tg_port2
}

