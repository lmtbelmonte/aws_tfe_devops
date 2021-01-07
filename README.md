# Modelo devops similar a Terraform Enterprise combinando terraform , Aws pipeline 
#
No se incluye el terraform.tfvars que es necesario para su funcionamiento con el formato

# terraform.tfvars

aws = {
  access_key = "AKIXXXXXXXXXXXXXXXXX"
  secret_key = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  region     = "us-east-1"
}
vcs_repo = {
  branch      = "master"
  identifier  = "lmtbelmonte/nombre_repo"
  oauth_token = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

