resource "aws_vpc" "ruturaj" {
  cidr_block = "10.10.0.0/16"
  tags = { Name = "Ruturaj" }
}

resource "aws_subnet" "public1" {
  vpc_id     = aws_vpc.ruturaj.id
  cidr_block = "10.10.1.0/24"
  tags       = { Name = "public1" }
}

resource "aws_subnet" "private1" {
  vpc_id     = aws_vpc.ruturaj.id
  cidr_block = "10.10.2.0/24"
  tags       = { Name = "private1" }
}

resource "aws_internet_gateway" "IGW1" {
  vpc_id = aws_vpc.ruturaj.id
  tags   = { Name = "IGW" }
}

resource "aws_route_table" "r1" {
  vpc_id = aws_vpc.ruturaj.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW1.id
  }
  tags = { Name = "MRT1" }
}

resource "aws_eip" "EIP1" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat1" {
  subnet_id     = aws_subnet.public1.id
  allocation_id = aws_eip.EIP1.id
}

resource "aws_route_table" "r2" {
  vpc_id = aws_vpc.ruturaj.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat1.id
  }
  tags = { Name = "CRT1" }
}

resource "aws_route_table_association" "A1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.r1.id
}

resource "aws_route_table_association" "A2" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.r2.id
}

resource "aws_key_pair" "rutu" {
  key_name   = "Public_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC3PLxjXD8tGy5nwEEeMSb4bnG91EEH1kWtTke/lZeF7pf34541q49l+i12mSKPcnpLCmFEpLQpPSmAlsq3m+e2DR9RUdMUS6W4DiNSIklEnpqLs4FAzjFch0VF1xaNzdZHqI1SVfaSDO4qEJUriYLhgU7GPzSeoNOWdLwDyOetrmdUNVi6qTdlAvS2+/Hl1vfPxNrR1Mu/an22xrEgpWRBe0ROWLJerbFLRcptPKaJ+GvoReZZ4sQW/E0v3OxfZ8QcNhtoQ4W8oaoP6KLq3BElpdaC63so11cE4Cqn/oR4FjyM8hLHb39BaoJ19EYRDL61s/LgQUUptdy0oGzWTRI6w9CFCgAqXKqfNtj3xuLWG1GzQYaOnA/IkbjQDgJasxijneKWHFsrW1AYyEQ2BTOAfGlApRbobvr533n3uysxyk9G6UI4SDC2oBikb+0TT+spcq6uDVSdNAm8UDc6AmObDFvWaLSWK25EY16VxZ+4H1OfWRjVHABd/aWtqNAIS8s= ruturajtekale56@gmail.com"
}

# Corrected Security Group (Ensured it's inside the VPC)
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.ruturaj.id  # Explicitly tied to the correct VPC

  tags = { Name = "all traffic" }
}

resource "aws_vpc_security_group_ingress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Allows all inbound traffic
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # Allows all outbound traffic
}

resource "aws_instance" "My_server" { 
  ami                    = "ami-05b10e08d247fb927"
  instance_type          = "t2.medium"
  key_name               = aws_key_pair.rutu.id
  subnet_id              = aws_subnet.public1.id  
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  associate_public_ip_address = true

  user_data = <<-EOF
    sudo yum install java-17* -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo dnf upgrade
    sudo yum install jenkins -y
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
  EOF

  tags = { Name = "EC2 server"}
}
