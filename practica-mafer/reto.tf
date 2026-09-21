resource "google_compute_subnetwork" "privada" {
  name          = "${var.prefijo}-sub-privada"
  ip_cidr_range = var.cidr_privada
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_router" "router" {
  name    = "${var.prefijo}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                   = "${var.prefijo}-nat"
  router                 = google_compute_router.router.name
  region                 = var.region
  nat_ip_allocate_option = "AUTO_ONLY"   

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.privada.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_instance" "datos" {
  name         = "${var.prefijo}-datos"
  machine_type = var.tipo_maquina
  zone         = var.zona
  tags         = ["datos"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privada.id
  }

  metadata_startup_script = file("${path.module}/datos.sh")

  depends_on = [google_compute_router_nat.nat]
}

resource "google_compute_firewall" "app_a_datos" {
  name    = "${var.prefijo}-permitir-app-a-datos"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_tags = ["http-server"]   
  target_tags = ["datos"]          
}