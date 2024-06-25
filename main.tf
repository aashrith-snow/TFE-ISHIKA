data "aws_ami" "image" {
  most_recent      = true
  owners           = ["amazon"]

  filter {
    name   = "name"
    values = ["${var.ami}"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "basic_vm" {
  ami           = data.aws_ami.image.id
  instance_type = var.instancetype
  key_name      = var.keyname
  subnet_id	    = var.subnet
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    iops                  = (var.root_volume_type == "io1" || var.root_volume_type == "io2") ? 100 : null
  }
}
resource "aws_ebs_volume" "ebs_volumes" {
  for_each = { for idx, disk in var.disks : idx => disk }
  availability_zone = aws_instance.basic_vm.availability_zone
  size = each.value.volume_size
  type = each.value.volume_type
  iops = (each.value.volume_type == "io1" || each.value.volume_type=="io2") ? 100 : null
}

resource "aws_volume_attachment" "ebs_volume_attachments" {
  for_each = aws_ebs_volume.ebs_volumes
  device_name = "/dev/sd${substr("fghijklmnop", each.key, 1)}"
  volume_id   = each.value.id
  instance_id = aws_instance.basic_vm.id
}
locals {ebs_block_devices =  var.disks}
