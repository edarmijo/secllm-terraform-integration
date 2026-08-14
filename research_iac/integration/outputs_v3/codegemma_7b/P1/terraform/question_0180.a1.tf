provider "aws" {
  region = "us-east-1"
}

variable "notebook_name" {
  type = string
  default = "my-notebook"
}

variable "instance_type" {
  type = string
  default = "ml.t2.medium"
}

resource "aws_sagemaker_notebook_instance" "example" {
  name = var.notebook_name
  instance_type = var.instance_type

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_sagemaker_notebook_instance_lifecycle_config" "example" {
  name = "my-lifecycle-config"

  notebook_instance_lifecycle_config_content = <<EOF
{
  "start_steps": [
    {
      "name": "Install Terraform",
      "action": "RUN",
      "content": "curl -O https://releases.hashicorp.com/terraform/latest/terraform_linux_amd64 && chmod +x terraform && mv terraform /usr/local/bin/"
    }
  ]
}
EOF
}

resource "aws_sagemaker_notebook_instance_lifecycle_hook" "example" {
  notebook_instance_lifecycle_config_name = aws_sagemaker_notebook_instance_lifecycle_config.example.name
  lifecycle_hook_name = "InstallTerraform"
  content = aws_sagemaker_notebook_instance_lifecycle_config.example.notebook_instance_lifecycle_config_content
}