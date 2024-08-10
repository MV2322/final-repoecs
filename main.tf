provider "aws" {
  region = var.aws.region
}

resource "aws_ecs_cluster" "mycluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_task_definition" "my-tdf" {
  family = "my-task"
  container_definitions = jsonencode([
    {
     name = "my-container"
     image= "nginx:latest"
     cpu  = 256
     memory = 512
     essential = true
    }
   ])
}

resource "aws_ecs_service" "my-svc" {
  name     = "my-service"
  cluster  = aws_ecs_cluster.mycluster.id
  task_definition = aws_ecs_task_definition.my-tdf.arn
  desired_count = 1

  network_configuration {
    subnets  = ["subnet-00308d31ff7843ef4"]
    security_groups = ["sg-089533e553718c99c"]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_lb_target.mylb.arn
    container_name  = "my-container"
    container_port  = 80
  }
  depends_on = [
    aws_lb_listener.mylb
  ]
}
resource "aws_lb" "my-loadbalancer" {
  name   =  "my-lb"
  internal = false
  load_balancer_type = "application"
  security_groups  = ["sg-089533e553718c99c"]
  subnets  = ["subnet-00308d31ff7843ef4"]
}

resource "aws_lb_listener" "my-listener" {
  load_balancer_arn = aws_lb.my-loadbalancer.arn
  port = 80
  protocol = "HTTP"
 
  default_action {
    type  = "fixed-response"
    fixed-response {
      content_type = "text/plain"
      message_body = "OK"
      status_code  = "200"
    }
  }
}
resource "aws_lb_target_group" "my-tg" {
  name  = "my-target-group"
  port  = 80
  protocol = "HTTP"
}

output "load_balancer_dns_name" {
  value = aws_lb.my-loadbalancer.dns_name
}
 