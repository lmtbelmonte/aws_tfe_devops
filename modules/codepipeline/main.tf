# Luis merino : Manning - automatizacion IaC con DevOps 
# 
# Module para AWS Pipeline 

# main.tf - main del modulo codepipeline

# Creamos un string random para evitar colisiones con los namespaces 
resource "random_string" "rand" {
  length  = 24
  special = false
  upper   = false
}

locals {
  namespace = substr(join("-", [var.name, random_string.rand.result]), 0, 24)
}

# Provisionamos los dos codebuild 
locals {
  projects = ["plan", "apply"]
}

# Utilizamos la image con terraform que nos provee hashicorp de forma que no habria 
# que descargarla cada vez, va unida a la version que en este caso es latest 
# la he metido temporalmente en Quay.io mya que docker tiene una limitacion de pulls en el free

resource "aws_codebuild_project" "project" {
  count        = length(local.projects)
  name         = "${local.namespace}-${local.projects[count.index]}"
  service_role = aws_iam_role.codebuild_role.id

  artifacts {
    type = "NO_ARTIFACTS"
  }

# Para las environment variables definidas por el usuario ( aws keys) se juntan en un nuevo map
# este nuevo map es convertido en una lita JSON con una expresion for
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "quay.io/lmtbelmonte01/terraform:${var.terraform_version}" 
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "NO_SOURCE"
    buildspec = file("${path.module}/templates/buildspec_${local.projects[count.index]}.yml")
  }
}

 locals {
  backend = templatefile("${path.module}/templates/backend.json", { config : var.s3_backend_config, name : local.namespace })
 
  default_environment = {
    TF_IN_AUTOMATION  = "1"
TF_INPUT          = "1"
CONFIRM_DESTROY   = "0"
    WORKING_DIRECTORY = var.working_directory
    BACKEND           = local.backend,
  }
 
  environment = jsonencode([for k, v in merge(local.default_environment, var.environment) : { name : k, value : v, type : "PLAINTEXT" }])
}

# creamos el bucket s3 para el pipeline y el sns topic para confirmacion
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket        = "${local.namespace}-codepipeline-bucket"
  acl           = "private"
  force_destroy = true
}
 
resource "aws_sns_topic" "codepipeline" {
  name = "${local.namespace}-pipeline-topic"
}

# creamos el pipeline que realiza 4 acciones
#   Source   : crea un webhook y descargsa el source del git
#   Plan     : corre un terraform plan con el source code
#   Approve  : espera a una aprobacion 
#   Apply    : corre un terraform apply

resource "aws_codepipeline" "codepipeline" {
  name     = "${local.namespace}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
 
  artifact_store {
    location = aws_s3_bucket.codepipeline_bucket.bucket
    type     = "S3"
  }
 
  stage {
    name = "Source"
 
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]
 
      configuration = {
        Owner      = split("/", var.vcs_repo.identifier)[0]
        Repo       = split("/", var.vcs_repo.identifier)[1]
        Branch     = var.vcs_repo.branch
        OAuthToken = var.vcs_repo.oauth_token
      }
    }
  }
 
  stage {
    name = "Plan"
 
    action {
      name            = "Plan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
 
      configuration = {
        ProjectName          = aws_codebuild_project.project[0].name
        EnvironmentVariables = local.environment
      }
    }
  }
 
  dynamic "stage" {
    for_each = ! var.auto_apply ? [1] : []
    content {
      name = "Approval"
 
      action {
        name     = "Approval"
        category = "Approval"
        owner    = "AWS"
        provider = "Manual"
        version  = "1"
 
        configuration = {
          CustomData         = "Please review output of plan and approve"
          NotificationArn    = aws_sns_topic.codepipeline.arn
        }
      }
    }
  }
 
  stage {
    name = "Apply"
 
    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"
 
      configuration = {
        ProjectName          = aws_codebuild_project.project[1].name
        EnvironmentVariables = local.environment
      }
    }
  }
}