variable "vpc_id"{
  default = ""
}

variable "profile_ic" {
  default= ""
}
variable "region" {
  default = "ca-central-1"
}

variable "account_ic" {
  default = ""
}

variable "subnet_tag" {
  default = ""
}

variable "tg_asn" {
  default = ""
}

variable "rt_name" {
  default = ""
}

variable "tag_accepter" {
  default= ""
}

variable "cidr_blocks" {
  type = list
  default = [""]

}