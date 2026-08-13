provider "aws" {
  region = "us-east-1"
}

data "aws_kendra" "kendra_index" {
  name = "my-kendra-index"
}

resource "aws_kendra_data_source" "kendra_data_source" {
  name = "my-kendra-data-source"
  index_id = data.aws_kendra.kendra_index.id

  configuration {
    url_configuration {
      exclusion_patterns = ["/excluded-path/*"]
      inclusion_patterns = ["/included-path/*"]
    }
  }
}