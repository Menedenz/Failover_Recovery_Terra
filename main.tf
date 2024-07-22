# VPC resource
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.vpc_name}-${var.project}-${var.env}"
  }
}

# Subnet A resource
resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_a_cidr
  availability_zone = var.availability_zone_a

  tags = {
    Name = "${var.subnet_a_name}-${var.project}-${var.env}"
  }
}

# Subnet B resource
resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_b_cidr
  availability_zone = var.availability_zone_b

  tags = {
    Name = "${var.subnet_b_name}-${var.project}-${var.env}"
  }
}

# Internet Gateway resource
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.igw_name}-${var.project}-${var.env}"
  }
}

# Route Table resource
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.route_table_name}-${var.project}-${var.env}"
  }
}

# Security Group resource
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.security_group_name_ec2}-${var.project}-${var.env}"
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.security_group_name_alb}-${var.project}-${var.env}"
  }
}

# Route Table Associations
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.main.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.main.id
}


# EC2 (Key --> data "aws_ami" --> aws_instance)
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_name)
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "active_EC2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.subnet_a.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data       = templatefile("${path.module}/active_user_data.sh", { cert_content = file(var.cert_file), key_content = file(var.key_file), APACHE_LOG_DIR = var.apache_log_dir })
  associate_public_ip_address = true
  tags = {
    Name          = "${var.active_ec2_name}-${var.project}-${var.env}"
  }
}

resource "aws_instance" "passive_EC2" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.subnet_b.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data       = templatefile("${path.module}/passive_user_data.sh", { cert_content = file(var.cert_file), key_content = file(var.key_file), APACHE_LOG_DIR = var.apache_log_dir })
  associate_public_ip_address = true
  tags = {
    Name          = "${var.passive_ec2_name}-${var.project}-${var.env}"
  }
}

# Targer groups --> ALB

# Create Target Groups
resource "aws_lb_target_group" "active_tg" {
  name        = "active-tg-${var.project}-${var.env}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
  }
}

resource "aws_lb_target_group" "passive_tg" {
  name        = "passive-tg-${var.project}-${var.env}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol = "HTTPS"
    port     = "traffic-port"
  }
}

# Attach Active Instances to Active Target Group
resource "aws_lb_target_group_attachment" "active_tg" {
  target_group_arn = aws_lb_target_group.active_tg.arn
  target_id        = aws_instance.active_EC2.id
  port             = 443
}

# Attach Passive Instances to Passive Target Group
resource "aws_lb_target_group_attachment" "passive_tg" {
  target_group_arn = aws_lb_target_group.passive_tg.arn
  target_id        = aws_instance.passive_EC2.id
  port             = 443
}


# create ALB
resource "aws_lb" "alb_active_passive" {
  name               = "alb-${var.project}-${var.env}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
}

# Listener on port 80
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb_active_passive.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Listener on port 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb_active_passive.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "forward"

    forward {
      target_group {
        arn   = aws_lb_target_group.active_tg.arn
        weight = 100
      }

      target_group {
        arn   = aws_lb_target_group.passive_tg.arn
        weight = 0
      }
    }
  }
}


# alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_active_ec2" {
  alarm_name          = "Unhealthy-Active-EC2-terrafrom"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  actions_enabled     = true
  alarm_description   = "No description"

  dimensions = {
    TargetGroup      = aws_lb_target_group.active_tg.arn_suffix
    LoadBalancer     = aws_lb.alb_active_passive.arn_suffix
    AvailabilityZone = "us-east-1a"
  }

  treat_missing_data = "breaching"
  alarm_actions      = [aws_lambda_function.FailoverRecovery.arn]
}

# lambda function
resource "aws_lambda_function" "FailoverRecovery" {
  function_name = var.lambda_function_name
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_role.arn
  filename      = "${path.module}/FailoverALBTG.zip"
  timeout       = 10

  source_code_hash = filebase64sha256("${path.module}/FailoverALBTG.zip")

  environment {
    variables = {
      ALB_ARN                   = aws_lb.alb_active_passive.arn
      EVENT_RULE_NAME           = var.event_rule_name
      INSTANCE_ID               = aws_instance.active_EC2.id
      LISTENER_ARN              = aws_lb_listener.https.arn
      OPERATION                 = var.operation
      TARGET_GROUP_ACTIVE_ARN   = aws_lb_target_group.active_tg.arn
      TARGET_GROUP_PASSIVE_ARN  = aws_lb_target_group.passive_tg.arn
    }
  }
}

# resoruce based policy
resource "aws_lambda_permission" "allow_event_invoke" {
  statement_id  = "AllowExecutionFromCloudWatchEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.FailoverRecovery.function_name
  principal     = "events.amazonaws.com"
  source_arn    = "arn:aws:events:us-east-1:533267287905:rule/ActiveIISRecoveryEvent"
}


resource "aws_lambda_permission" "allow_alarm_invoke" {
  statement_id  = "AllowExecutionFromCloudWatchAlarms"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.FailoverRecovery.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
  source_arn    = aws_cloudwatch_metric_alarm.unhealthy_active_ec2.arn
}

# create IAM Role and attach it to lambda
# step 1 create the create the role and say what service (priciple) can use this role in our case its lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role_terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_inline_policy" {
  name   = "lambda_inline_policy"
  role   = aws_iam_role.lambda_role.id

  # Read the JSON policy document from a file
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstanceStatus"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "elasticloadbalancing:ModifyListener"
        ],
        Resource = aws_lb_listener.https.arn
      },
      {
        Effect = "Allow",
        Action = [
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:DeleteRule"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "lambda:UpdateFunctionConfiguration"
        ],
        Resource = aws_lambda_function.FailoverRecovery.arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup"
        ],
        Resource = "arn:aws:logs:us-east-1:533267287905:*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:us-east-1:533267287905:log-group:/aws/lambda/FailoverRecover:*"
        ]
      }
    ]
  })
}