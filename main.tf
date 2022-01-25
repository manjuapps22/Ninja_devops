terraform {
  backend "s3" {
    bucket = "terraform-backend-bucket-3446"
    key    = "path/terraform/statefiles"
    region = "us-east-1"
  }
}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_subnet" "subone" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "sub1"
  }
}
resource "aws_subnet" "subtwo" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "sub2"
  }
}
resource "aws_subnet" "subthree" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "sub3"
  }
}
resource "aws_subnet" "subfour" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "sub4"
  }
}

resource "aws_eip" "nat_ip" {
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.subone.id

  tags = {
    Name = "gw NAT"
  }
}

resource "aws_route_table" "Public_rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public"
  }
}
resource "aws_route_table" "Private_rt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgw.id
  }

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "rt-publicone-association" {
  subnet_id      = aws_subnet.subone.id
  route_table_id = aws_route_table.Public_rt.id
}

resource "aws_route_table_association" "rt-publictwo-association" {
  subnet_id      = aws_subnet.subtwo.id
  route_table_id = aws_route_table.Public_rt.id
}

resource "aws_route_table_association" "rt-publicthree-association" {
  subnet_id      = aws_subnet.subthree.id
  route_table_id = aws_route_table.Private_rt.id
}

resource "aws_route_table_association" "rt-publicfour-association" {
  subnet_id      = aws_subnet.subfour.id
  route_table_id = aws_route_table.Private_rt.id
}


resource "aws_security_group" "ssh_public" {
  vpc_id = aws_vpc.myvpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ssh_private" {
  vpc_id = aws_vpc.myvpc.id
  ingress {
    cidr_blocks = [
      "10.0.0.0/16"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name = "sammm"
  subnet_id = aws_subnet.subone.id
  associate_public_ip_address = "true"
  vpc_security_group_ids =[aws_security_group.ssh_public.id]
  tags = {
    Name = "Bastion"
  }
}

resource "aws_instance" "jenkin" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name = "sammm"
  subnet_id = aws_subnet.subthree.id
  associate_public_ip_address = "false"
  vpc_security_group_ids =[aws_security_group.ssh_private.id]
  tags = {
    Name = "Jenkin"
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-04505e74c0741db8d"
  instance_type = "t2.micro"
  key_name = "sammm"
  subnet_id = aws_subnet.subfour.id
  associate_public_ip_address = "false"
  vpc_security_group_ids =[aws_security_group.ssh_private.id]
  tags = {
    Name = "Application"
  }
}
