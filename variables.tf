variable "access_key" {}
variable "secret_key" {}
variable "region" {}
variable "subnet" {}
variable "network" {}
variable "instancetype" {}
variable "ami" {}
variable "keyname" {}
variable "root_volume_size"{}
variable "root_volume_type"{}
variable "disks" {
  type = list(object({
    volume_size  = number
    volume_type  = string
  }))
  default=[]
}