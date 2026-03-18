data "aws_iam_policy_document" "karpenter_controller_assume" {
  count = var.k3s_enabled ? 1 : 0

  statement {
    sid     = "AllowK3sServiceAccountAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.k3s.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.k3s.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.k3s.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count              = var.k3s_enabled ? 1 : 0
  name               = "karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume[0].json

  tags = module.context.tags
}

data "aws_iam_policy_document" "karpenter_controller" {
  count = var.k3s_enabled ? 1 : 0

  # Adapted from the official Karpenter v1.9 AWS controller policies for a non-EKS K3s control plane.
  statement {
    sid = "AllowScopedEC2InstanceAccessActions"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}::image/*",
      "arn:aws:ec2:${data.aws_region.current.region}::snapshot/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:security-group/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:subnet/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:capacity-reservation/*",
    ]
  }

  statement {
    sid = "AllowScopedEC2LaunchTemplateAccessActions"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:*:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowScopedEC2InstanceActionsWithTags"
    actions = [
      "ec2:RunInstances",
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:*:fleet/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:instance/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:volume/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:network-interface/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:launch-template/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:spot-instances-request/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [local.k3s_cluster_name]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowScopedResourceCreationTagging"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:*:fleet/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:instance/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:volume/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:network-interface/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:launch-template/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:spot-instances-request/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [local.k3s_cluster_name]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowScopedResourceTagging"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:*:instance/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [local.k3s_cluster_name]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["eks:eks-cluster-name", "karpenter.sh/nodeclaim", "Name"]
    }
  }

  statement {
    sid = "AllowScopedDeletion"
    actions = [
      "ec2:TerminateInstances",
      "ec2:DeleteLaunchTemplate",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.region}:*:instance/*",
      "arn:aws:ec2:${data.aws_region.current.region}:*:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowPassingInstanceRole"
    actions = [
      "iam:PassRole",
      "iam:GetRole",
    ]
    resources = [
      aws_iam_role.k3s_agent_node[0].arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "ec2.amazonaws.com.cn"]
    }
  }

  statement {
    sid = "AllowScopedInstanceProfileCreationActions"
    actions = [
      "iam:CreateInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [local.k3s_cluster_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [data.aws_region.current.region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowScopedInstanceProfileTagActions"
    actions = [
      "iam:TagInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [data.aws_region.current.region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [local.k3s_cluster_name]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/topology.kubernetes.io/region"
      values   = [data.aws_region.current.region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowScopedInstanceProfileActions"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.k3s_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/topology.kubernetes.io/region"
      values   = [data.aws_region.current.region]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  statement {
    sid = "AllowRegionalReadActions"
    actions = [
      "ec2:DescribeCapacityReservations",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [data.aws_region.current.region]
    }
  }

  statement {
    sid = "AllowSSMReadActions"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.region}::parameter/aws/service/*",
    ]
  }

  statement {
    sid = "AllowPricingReadActions"
    actions = [
      "pricing:GetProducts",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowUnscopedInstanceProfileListAction"
    actions = [
      "iam:ListInstanceProfiles",
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowInstanceProfileReadActions"
    actions = [
      "iam:GetInstanceProfile",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:instance-profile/*",
    ]
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  count  = var.k3s_enabled ? 1 : 0
  name   = "karpenter-controller-policy"
  policy = data.aws_iam_policy_document.karpenter_controller[0].json

  tags = module.context.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  count      = var.k3s_enabled ? 1 : 0
  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
}
