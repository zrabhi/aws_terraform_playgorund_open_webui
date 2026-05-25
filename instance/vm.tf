
resource "aws_security_group" "ubuntu_open_webui" {

    name    = "ubuntu_open_webui"
    description = "Allow HTTP and SSH traffic to the instance"

    
 

ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
   
    
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["Your_Public_IP/32"]
    }
}

data "aws_ami" "ubuntu" {
  most_recent      = true
  owners           = ["099720109477"]


  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh_key" {
    key_name = "ssh_key"
    public_key = file("/tmp/ssh_pub_key")
}

resource "aws_instance" "ubuntu_open_webui" {
    ami           =  "ami-0be40a46b4111e7f5"
    instance_type = "t3.micro"
    user_data_base64     = base64encode(file("${path.module}/config/provision.sh"))
    
    associate_public_ip_address = true
    key_name = aws_key_pair.ssh_key.key_name
    vpc_security_group_ids = [aws_security_group.ubuntu_open_webui.id]
    tags = {
        Name = "ec2_open_webui1"
    } 
    root_block_device {
        volume_size = 60
    }
}
resource "terracurl_request" "open_webui" {
    name = "open_webui"
    url = "http://${aws_instance.ubuntu_open_webui.public_ip}/api/health"
    method = "GET"

    response_codes = [200]
    max_retry = 120
    retry_interval = 15

}
