#!/usr/bin/env bash
#
# install-terraform-ubuntu.sh
# Installs Terraform on Ubuntu using HashiCorp's official apt repository.
#
# Usage:
#   chmod +x install-terraform-ubuntu.sh
#   ./install-terraform-ubuntu.sh            # installs the latest version
#   ./install-terraform-ubuntu.sh 1.9.5      # installs a specific version

set -euo pipefail

VERSION="${1:-}"

echo "==> Updating package index..."
sudo apt-get update -y

echo "==> Installing prerequisites (gnupg, software-properties-common, curl, lsb-release)..."
sudo apt-get install -y gnupg software-properties-common curl lsb-release

echo "==> Adding the HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "==> Adding the HashiCorp apt repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "==> Updating package index again..."
sudo apt-get update -y

if [[ -z "$VERSION" ]]; then
  echo "==> Installing latest Terraform..."
  sudo apt-get install -y terraform
else
  echo "==> Installing Terraform version ${VERSION}..."
  sudo apt-get install -y "terraform=${VERSION}-*"
fi

echo "==> Verifying installation..."
terraform -version

echo "==> Done. Terraform installed successfully."
