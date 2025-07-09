provider "aws" {
  region                   = "us-east-2"
  shared_config_files      = ["/Users/alanrdz/.aws/config"]
  shared_credentials_files = ["/Users/alanrdz/.aws/credentials"]
}


resource "aws_iam_role" "EKS_role" {
  name = "terraform-eks-cluster-role"
  assume_role_policy = jsonencode({
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "EKS_role_privs" {
  role       = aws_iam_role.EKS_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_eks_cluster" "terraform_eks" {
  name     = "terraform-tasky"
  role_arn = aws_iam_role.EKS_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.terraform_private_subnet_1.id,
      aws_subnet.terraform_private_subnet_2.id
    ]
  }
}

resource "aws_iam_role" "workerNodeRole" {
  name = "EKS-worker-node-role"
  assume_role_policy = jsonencode(
    {
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
    }
  )
}

resource "aws_iam_role_policy_attachment" "nodeWorkerAttachment" {
  role       = aws_iam_role.workerNodeRole.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_role_policy_attachment" "nodeWorkerAttachment2" {
  role       = aws_iam_role.workerNodeRole.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "nodeWorkerAttachment3" {
  role       = aws_iam_role.workerNodeRole.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "nodeWorkerAttachment4" {
  role       = aws_iam_role.workerNodeRole.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ELBControllerIAMRole" {
  role   = aws_iam_role.workerNodeRole.id
  policy = file("alb_controller_iam_policy.json")
}

resource "aws_eks_node_group" "eks_nodegroups_tf" {
  cluster_name    = aws_eks_cluster.terraform_eks.name
  node_group_name = "terraform_NG"



  subnet_ids = [
    aws_subnet.terraform_private_subnet_1.id,
    aws_subnet.terraform_private_subnet_2.id
  ]
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }
  instance_types = ["t3.small"]
  node_role_arn  = aws_iam_role.workerNodeRole.arn
}
resource "aws_iam_openid_connect_provider" "eks_irsa" {
  url            = aws_eks_cluster.terraform_eks.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "irsa" {
  name = "irsa_role"
  path = "/"
  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_irsa.arn
      }
    }]
    }
  )
}

resource "aws_iam_policy" "lbc" {
  name   = "lbc-tasky-terraform"
  path   = "/"
  policy = file("/Users/alanrdz/Kubernetes/alb_controller_iam_policy.json")
}

resource "aws_iam_policy_attachment" "lbc_attachment" {
  roles      = [aws_iam_role.irsa.id]
  policy_arn = aws_iam_policy.lbc.arn
  name       = "lbc-attachment-perms"
}
provider "helm" {
  kubernetes = {
    host                   = aws_eks_cluster.terraform_eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.terraform_eks.certificate_authority[0].data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.terraform_eks.name]
      command     = "aws"
    }
  }
}

resource "helm_release" "aws_lbc" {
  name            = "aws-load-balancer-controller"
  repository      = "https://aws.github.io/eks-charts"
  chart           = "aws-load-balancer-controller"
  namespace       = "kube-system"
  cleanup_on_fail = true
  set = [{
    name  = "clusterName"
    value = aws_eks_cluster.terraform_eks.name
    },
    {
      name  = "serviceAccount.create"
      value = true
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.irsa.arn
    },
    {
      name  = "region"
      value = "us-east-2"
    },
    {
      name  = "vpcId"
      value = aws_vpc.terraform_vpc.id
    },
  ]
}