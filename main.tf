terraform {
  backend "s3" {
    bucket = "vai2023"
    key    = "myapp/dev/terraform.tfstate"
    region = "us-east-2"
   // dynamodb_table = "dynamodb-state-locking"
  }
}




provider "aws" {
  profile = "default"
  region  = var.region
  access_key = var.acc_id
  secret_key = var.sec_key
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_availability_zones" "available" { }


resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for us-west-1a"
  }
}



resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow 22 and 8080 traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}



resource "aws_instance" "foo" {
  ami           = "ami-0ada6d94f396377f2" # us-west-2
  instance_type = "t2.medium"
  subnet_id = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [ aws_security_group.allow_tls.id ]
  key_name = "vaio16"

  tags = {
    "Name" = "JJserver"
  }



}



resource "null_resource" "name" {
    #ssh into ec2 instance

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("/home/ubuntu/vaio16.pem")
      host = aws_instance.foo.public_ip


    }
    #copy the install_jenkins files to the ec2 instance

    provisioner "file"{
      source = "install_jenkins.sh"
      destination = "/tmp/install_jenkins.sh"



    }
    #set executable permission and install jenkish file
     provisioner "remote-exec"{
        inline = [
         "sudo chmod +x /tmp/install_jenkins.sh",
         "sh /tmp/install_jenkins.sh"

         ]

     }

   depends_on = [
       aws_instance.foo

]



}



