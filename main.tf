provider "aws" {
    region = "sa-east-1"
    profile = "terraform"  # Name of your aws profile
}

resource "aws_key_pair" "keypair" {
  key_name   = "machine-key"  # Name of ec2 keypair
  public_key = file("~/.ssh/id_rsa.pub")  # Filepath of the key
}

resource "aws_instance" "project-server" {
  ami           = "ami-0b6c2d49148000cd5"  
  instance_type = "t2.micro"
  key_name      = aws_key_pair.keypair.key_name
  availability_zone = "sa-east-1a"
  tags = {
    Name = "webserver" 
  }
  vpc_security_group_ids = [aws_security_group.sg_webserver.id]

  root_block_device {
    volume_type           = "gp2"  // Tipo de volume EBS (por exemplo, gp2 para SSD)
    volume_size           = 20     // Tamanho do volume raiz em GB
    delete_on_termination = true  // O volume será excluído quando a instância for terminada
  }


  provisioner "local-exec" {
    command = "sleep 30"
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${self.public_ip} >> ~/.ssh/known_hosts"
  }

   provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' -u ubuntu -i ~/.ssh/id_rsa.pub -e 'external_ip=${self.public_ip}' Ansible/InstallDocker.yaml"
  }

     provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},'    -u ubuntu -i ~/.ssh/id_rsa.pub -e 'external_ip=${self.public_ip}' Ansible/InstallNagiosPlugins.yaml"
  }

}

resource "aws_security_group" "sg_webserver" {
  name        = "sg_webserver"
  description = "SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0   
    to_port     = 0   
    protocol    = "-1" 
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

output "public_ip" {
  value = aws_instance.project-server.public_ip
}