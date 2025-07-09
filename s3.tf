resource "aws_s3_bucket" "pipeline-terraform-s3-bucket-alanrdze" {
  bucket = "pipeline-terraform-s3-bucket-alanrdze"
}

resource "aws_s3_bucket_public_access_block" "s3bucketpublic" {
  bucket                  = aws_s3_bucket.terraform-s3-bucket-alanrdze.id
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  block_public_acls       = true
}