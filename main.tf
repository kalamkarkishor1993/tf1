resource "aws_security_group" "firewall" {
  name   = "test-sg"
  vpc_id = "vpc-0c2f14cfb74e3d1de"

  # Fix 1: ingress = {} चुकीचं होतं → ingress {} block syntax
  # Fix 2: cidr_blcok → cidr_blocks (spelling fix)
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

resource "aws_instance" "vm" {
  ami                    = "ami-0e38835daf6b8a2b9"
  instance_type          = "t3.micro"
  key_name               = "ssh_key"
  vpc_security_group_ids = [aws_security_group.firewall.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo -i
    yum update -y
    yum install httpd -y
    systemctl start httpd
    systemctl enable httpd
    echo "hello world" > /var/www/html/index.html
  EOF

  # Fix 3: tags {} चुकीचं होतं → tags = {}
  tags = {
    Name = "server-01"
  }
}
