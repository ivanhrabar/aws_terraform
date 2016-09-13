provider "aws" {
    access_key = ""
    secret_key = ""
    region = "eu-central-1"
}

resource "aws_iam_role" "codedeploy_role" {
    name = "codedeploy_role"
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
	"Sid": "1",
	"Effect": "Allow",
	"Principal": {
            "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codedeploy_policy" {
    name = "codedeploy_policy"
    role = "${aws_iam_role.codedeploy_role.id}"
    policy = <<EOF
{
    "Statement": [
        {
            "Action": [
                "ec2:Describe*"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "Tag:getResources",
                "Tag:getTags",
                "Tag:getTagsForResource",
                "Tag:getTagsForResourceList"
            ],
            "Resource": [
                "*"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_codedeploy_app" "chess"
{
  name = "chess"
}

resource "aws_codedeploy_deployment_group" "chess-group"
{
  app_name = "${aws_codedeploy_app.chess.name}"
  deployment_group_name = "chessgroup"
  service_role_arn = "${aws_iam_role.codedeploy_role.arn}"
  ec2_tag_filter {
    key = "role"
    value = "CodeDeploy"
    type = "KEY_AND_VALUE"
  }
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

resource "aws_iam_role" "instance_role" {
    name = "instance_role"
    assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "instance_policy" {
    name = "instance_policy"
    role = "${aws_iam_role.instance_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:Describe*",
                "s3:Get*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "chess_instance" {
    name  = "chess_instance"
    roles = ["${aws_iam_role.instance_role.id}"]
}

resource "aws_instance" "chess_instance" {
    ami = "ami-ea26ce85"
    instance_type = "t2.micro"
    key_name  = "ihrabar"
    security_groups = ["chess_group"]
    iam_instance_profile = "${aws_iam_instance_profile.chess_instance.name}"
    user_data = "${file("./user_data.sh")}"
    tags = {
	Name = "chess_server"
        role = "CodeDeploy"
        }
}
