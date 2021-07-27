variable "region" {
  default = "ca-central-1"
}

variable "ou_list"{
    type = list
    default = []
}

variable "vpc_id"{
  default = "vpc-xxxxxxx"
}