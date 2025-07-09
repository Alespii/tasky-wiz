resource "aws_iam_role" "EC2MongoDBInstanceRole" {
  name = "EC2MongoDBInstanceRole"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2DBInstanceRoleAttachment" {
  role       = aws_iam_role.EC2MongoDBInstanceRole.id
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "Ec2InstanceProfile" {
  name = "EC2MongoDBInstanceRole"
  role = aws_iam_role.EC2MongoDBInstanceRole.name
}

resource "aws_security_group" "TFMongodbSG" {
  vpc_id = aws_vpc.terraform_vpc.id
  name   = "terraform_vpc"
}

resource "aws_vpc_security_group_ingress_rule" "sshIngress" {
  security_group_id = aws_security_group.TFMongodbSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  to_port           = 22
  from_port         = 22
}

resource "aws_vpc_security_group_ingress_rule" "sshIngressPrivate1" {
  security_group_id = aws_security_group.TFMongodbSG.id
  cidr_ipv4         = aws_subnet.terraform_private_subnet_1.cidr_block
  ip_protocol       = "tcp"
  to_port           = 27017
  from_port         = 27017
}

resource "aws_vpc_security_group_ingress_rule" "sshIngressPrivatew" {
  security_group_id = aws_security_group.TFMongodbSG.id
  cidr_ipv4         = aws_subnet.terraform_private_subnet_2.cidr_block
  ip_protocol       = "tcp"
  to_port           = 27017
  from_port         = 27017
}

resource "aws_vpc_security_group_egress_rule" "interntAccess" {
  security_group_id = aws_security_group.TFMongodbSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1

}

resource "aws_instance" "mongodbInstance" {

  iam_instance_profile        = aws_iam_instance_profile.Ec2InstanceProfile.name
  instance_type               = "t2.micro"
  ami                         = "ami-0c803b171269e2d72"
  user_data                   = file("userdata.sh")
  key_name                    = "wiz-keypair"
  subnet_id                   = aws_subnet.terraform_public_subnet_1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.TFMongodbSG.id
  ]
  tags = {
    "Name" = "terraform-mongodb"
  }
}
