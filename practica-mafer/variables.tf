# variables.tf
variable "proyecto"     { default = "maquinavirtual-507221" }
variable "prefijo"      { default = "mafer-vpc" }
variable "region"       { default = "us-central1" }
variable "cidr_publica" { default = "10.10.1.0/24" }
variable "zona"          { default = "us-central1-a" }
variable "tipo_maquina"  { default = "e2-micro" }
variable "cidr_privada"  { default = "10.10.2.0/24" }