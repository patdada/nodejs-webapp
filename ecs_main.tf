# Define the provider for AWS
provider "aws" {
  region = "us-east-1"
}

# Create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "vvd-ecs-cluster"
}

# Use an existing IAM role
data "aws_iam_role" "my_ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
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
    "name": "my-container",
    "image": "patdada/folly-docker:v1.0.0",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ],
    "platform": {
      "architecture": "ARM64"
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
    subnets          = ["subnet-0076c3f93f003fed7"]
    security_groups  = ["sg-0c7be697e44641f5c"]
    assign_public_ip = true
  }
}
