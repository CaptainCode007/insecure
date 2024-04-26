resource "aws_ecr_repository" "repository" {
  name = "wiz-image"  
  image_tag_mutability = "IMMUTABLE"
}


