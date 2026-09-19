# variables.tf
variable "proyecto"     { type = string }
variable "prefijo"      { type = string }
variable "region"       { type = string }
variable "cidr_publica" { type = string }
variable "zona"          { default = "us-central1-a" }
variable "tipo_maquina"  { default = "e2-micro" }
variable "cidr_privada"  { default = "10.10.2.0/24" }