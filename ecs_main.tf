# Define the provider for AWS
provider "aws" {
  region = "us-east-1"
}

# Create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "pato-ecs-cluster"
}

# Use an existing IAM role
data "aws_iam_role" "my_ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

# Create a multi-architecture Docker image
# Make sure to build and push this image to a container registry that supports multi-architecture manifests
# For example, Docker Hub, Amazon ECR, etc.

# Create a security group within the VPC
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Security group for ECS tasks"
  vpc_id      = "vpc-04bd3360983de3da0"  # Replace with your actual VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a task definition
resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "my-task-family-test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = data.aws_iam_role.my_ecs_task_execution_role.arn

  container_definitions = <<EOF
[
  {
    "name": "my-container-arm64",
    "image": "908778560637.dkr.ecr.us-east-1.amazonaws.com/netflix-app:v1",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "platform": {
      "architecture": "ARM64"
    }
  },
  {
    "name": "my-container-amd64",
    "image": "908778560637.dkr.ecr.us-east-1.amazonaws.com/netflix-app:v1",
    "portMappings": [
      {
        "containerPort": 81,
        "hostPort": 81
      }
    ],
    "platform": {
      "architecture": "AMD64"
    }
  }
]
EOF
}

# Create a service to run the task on the cluster
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-0d685514b95426815"]
    security_groups  = [aws_security_group.my_security_group.id]
    assign_public_ip = true
  }
}
