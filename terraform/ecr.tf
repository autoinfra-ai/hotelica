resource "aws_ecr_repository" "perplexica_backend" {
  name                 = "perplexica-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "perplexica_frontend" {
  name                 = "perplexica-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
