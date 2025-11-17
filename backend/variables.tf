variable "backend_region" { default = "us-east-1" }

variable "state_bucket_name" {
  default = "oneclick-terraform-state-bucket-anuu-2025"
}

variable "lock_table_name" {
  default = "oneclick-terraform-lock-anuu-2025"
}
