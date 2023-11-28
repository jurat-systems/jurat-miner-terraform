#!/bin/bash

echo -e "\e[44;37m"
echo "      _                 _     __  __ _                   ____       _               "
echo "     | |_   _ _ __ __ _| |_  |  \/  (_)_ __   ___ _ __  / ___|  ___| |_ _   _ _ __  "
echo "  _  | | | | | '__/ _| | __| | |\/| | | '_ \ / _ \ '__| \___ \ / _ \ __| | | | '_ \ "
echo " | |_| | |_| | | | (_| | |_  | |  | | | | | |  __/ |     ___) |  __/ |_| |_| | |_) |"
echo "  \___/ \__,_|_|  \__,_|\__| |_|  |_|_|_| |_|\___|_|    |____/ \___|\__|\__,_| .__/ "
echo "                                                                             |_|    "
echo -e "\e[0m"

echo ""

REQUIRED_VERSION="1.0.0"  # TERRAFORM VERSION

install_terraform() {
    echo "Installing Terraform version $REQUIRED_VERSION..."
    wget https://releases.hashicorp.com/terraform/${REQUIRED_VERSION}/terraform_${REQUIRED_VERSION}_linux_amd64.zip
    unzip terraform_${REQUIRED_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm terraform_${REQUIRED_VERSION}_linux_amd64.zip
    echo "Terraform installed successfully."
}

echo "Checking if terraform is available..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    install_terraform
else
    # Terraform is installed, check version
    INSTALLED_VERSION=$(terraform version -json | jq -r '.terraform_version')
    if [ "$INSTALLED_VERSION" = "$REQUIRED_VERSION" ]; then
        echo "Required Terraform version $REQUIRED_VERSION is already installed."
    else
        echo "Terraform version $INSTALLED_VERSION is installed, but version $REQUIRED_VERSION is required."
        install_terraform
    fi
fi

echo ""

echo "What AWS region would you like to use?"
echo "1) us-east-1"
echo "2) us-east-2"
echo "3) us-west-1"
echo "4) us-west-2"
read -p "Enter your choice: " aws_region

case $aws_region in
 1) aws_region="us-east-1" ;;
 2) aws_region="us-east-2" ;;
 3) aws_region="us-west-1" ;;
 4) aws_region="us-west-2" ;;
 *) echo "Invalid choice"; exit 1 ;;
esac

echo ""

echo "Select the size for your EC2 instance:"
echo "1) t2.small"
echo "2) t2.medium"
echo "3) t2.large"
read -p "Enter your choice (1/2/3): " instance_size

case $instance_size in
  1) instance_type="t2.small" ;;
  2) instance_type="t2.medium" ;;
  3) instance_type="t2.large" ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

echo ""

# Get AWS account ID from environment variables or ask user
aws_account_id=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null)
if [ -z "$aws_account_id" ]; then
  read -p "Enter your AWS account ID: " aws_account_id
fi

echo "Your AWS account ID is: $aws_account_id"

echo "Generating a cryptographic key-pair to access your Jurat miner."
# Generate key pair
key_name="jurat_ec2_key"
key_path="$HOME/.ssh/${key_name}.pem"
ssh-keygen -t rsa -f "$key_path" -q -N ""
chmod 400 "$key_path"

echo "Key-pair was created, and can be retrieved from: ${key_path}. Keep it safe!"

# Clone Terraform scripts
git clone https://github.com/jurat-github-repo/terraform-ec2.git # TODO: fix this
cd terraform-ec2

# Run Terraform
terraform init
terraform apply -auto-approve -var "instance_type=$instance_type" -var "key_name=$key_name" -var "key_path=$key_path" -var "aws_region=$aws_region" -var "aws_account_id=$aws_account_id"
