# Modelo devops similar a Terraform Enterprise combinando terraform , Aws pipeline 
#
No se incluye el terraform.tfvars que es necesario para su funcionamiento

# vcs_repo   
configura la conexion al GitHub repository
# identifier 
es el nombre del repo 
# branch
nombre de la branch
# oauth_token 
es el personal access token para los web hook.

# terraform.tfvars

aws = {
  access_key = "AKIXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  region     = "aws_region"
}
vcs_repo = {
  branch      = "master"
  identifier  = "github_user/nombre_repo"
  oauth_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

