cat > main.tf << 'EOF'
# main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google" }
  }
}

provider "google" {
  project = var.proyecto
  region  = var.region
}

# La VPC es global. En modo personalizado nace sin subredes.
resource "google_compute_network" "vpc" {
  name                    = "${var.prefijo}-vpc"
  auto_create_subnetworks = false
}

# La subred sí es regional, y es donde las máquinas toman su IP interna.
resource "google_compute_subnetwork" "publica" {
  name          = "${var.prefijo}-sub-publica"
  ip_cidr_range = var.cidr_publica
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Subred de datos: sin salida directa, solo alcanzable desde dentro de la VPC.
resource "google_compute_subnetwork" "datos" {
  name          = "${var.prefijo}-sub-datos"
  ip_cidr_range = var.cidr_privada
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Máquina de datos: sin access_config, no tiene IP pública.
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
    subnetwork = google_compute_subnetwork.datos.id
    # Sin access_config: no es alcanzable desde internet.
  }

  metadata_startup_script = file("${path.module}/arranque-datos.sh")
}

# Máquina de aplicación
resource "google_compute_instance" "app" {
  name         = "${var.prefijo}-app"
  machine_type = var.tipo_maquina
  zone         = var.zona
  tags         = ["app"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.publica.id
    access_config {}
  }

  # La app consulta la IP interna de "datos": esta referencia es
  # la dependencia real entre las dos máquinas.
  metadata_startup_script = templatefile("${path.module}/arranque.sh", {
    ip_datos = google_compute_instance.datos.network_interface[0].network_ip
  })
}

resource "google_compute_firewall" "app_http" {
  name    = "${var.prefijo}-permitir-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["app"]
}

resource "google_compute_firewall" "ssh_iap" {
  name    = "${var.prefijo}-permitir-ssh-iap"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # 35.235.240.0/20 es el rango desde el que Google reenvía SSH
  # a través de IAP. Es el único origen autorizado para el 22.
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["app"]
}

# Regla interna: solo la app (por etiqueta) puede hablarle a datos.
resource "google_compute_firewall" "datos_interno" {
  name    = "${var.prefijo}-permitir-datos-interno"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["app"]
  target_tags = ["datos"]
}

# Cloud Router: necesario como base para el NAT.
resource "google_compute_router" "router" {
  name    = "${var.prefijo}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

# Cloud NAT: permite que la máquina de datos salga a internet
# (para instalar paquetes) sin tener IP pública ni ser alcanzable desde afuera.
resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefijo}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
EOF