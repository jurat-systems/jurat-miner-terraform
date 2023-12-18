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

git clone https://github.com/jurat-systems/jurat-miner-terraform.git
cd jurat-miner-terraform

REQUIRED_VERSION="1.6.0"  # TERRAFORM VERSION
export TF_LOG=DEBUG

install_terraform() {
    echo "Installing Terraform version $REQUIRED_VERSION..."
    wget https://releases.hashicorp.com/terraform/${REQUIRED_VERSION}/terraform_${REQUIRED_VERSION}_linux_amd64.zip
    unzip terraform_${REQUIRED_VERSION}_linux_amd64.zip
    sudo mv terraform /usr/local/bin/ || true
    rm terraform_${REQUIRED_VERSION}_linux_amd64.zip
    echo "Terraform installed successfully."
}

create_key_pair() {
    export key_name="jurat_ec2_key"
    export key_path="$HOME/.ssh/${key_name}.pem"
    
    echo "Generating a cryptographic key-pair to access your Jurat miner."
    # Generate key pair
    if [ ! -e "$key_path" ]; then    
        ssh-keygen -t rsa -f "$key_path" -q -N ""
        chmod 400 "$key_path"
    fi

    export jurat_public_key=$(cat $key_path.pub)
}

echo "Checking if terraform is available..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null || true; then
    install_terraform
else
    # Terraform is installed, check version
    INSTALLED_VERSION=$(terraform version -json | jq -r '.terraform_version') || true
    if [ "$INSTALLED_VERSION" = "$REQUIRED_VERSION" ]; then
        echo "Required Terraform version $REQUIRED_VERSION is already installed."
    else
        echo "Terraform version $INSTALLED_VERSION is installed, but version $REQUIRED_VERSION is required."
        install_terraform
    fi
fi


# For now, the region is hard coded to Oregon (us-west-2). Uncomment code bellow in order to allow user to select different regions
export aws_region="us-west-2"

#echo ""
#
#echo "What AWS region would you like to use?"
#echo "1) us-east-1"
#echo "2) us-east-2"
#echo "3) us-west-1"
#echo "4) us-west-2"
#read -p "Enter your choice: " aws_region
#
#case $aws_region in
# 1) aws_region="us-east-1" ;;
# 2) aws_region="us-east-2" ;;
# 3) aws_region="us-west-1" ;;
# 4) aws_region="us-west-2" ;;
# *) echo "Invalid choice"; exit 1 ;;
#esac

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
create_key_pair

echo "Key-pair was created, and can be retrieved from: ${key_path}. Keep it safe!"

echo ""
read -p "What is the address of the wallet that should receive the mining proceeds? " wallet_address
echo $wallet_address > walletaddress

echo ""
read -p "Which email account would you like to use to receive alerts about the miner? " alert_email


# Creating tfvars to make life easier while using terraform after the setup is done

echo "instance_type = \"$instance_type\"" > terraform.tfvars
echo "key_name = \"$key_name\"" >> terraform.tfvars
echo "key_path = \"$key_path.pub\"" >> terraform.tfvars
echo "aws_region = \"$aws_region\"" >> terraform.tfvars
echo "aws_account_id = \"$aws_account_id\"" >> terraform.tfvars
echo "alert_email = \"$alert_email\"" >> terraform.tfvars
echo "jurat_public_key = \"$jurat_public_key\"" >> terraform.tfvars
echo "private_key_path = \"$key_path\"" >> terraform.tfvars

# Run Terraform
terraform init && terraform apply -auto-approve

#!/bin/bash

# Fetch the public IP address of the EC2 instance with the tag 'JuratMiner'
instance_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=JuratMiner" \
    --query "Reservations[*].Instances[*].PublicIpAddress" \
    --output text)

# Check if the IP address was successfully retrieved
if [ -z "$instance_ip" ]; then
    echo "Failed to retrieve the IP address for JuratMiner. Please ensure the instance is running and tagged correctly."
    exit 1
fi

# Update or Add the Host configuration in the .ssh/config file
ssh_config="$HOME/.ssh/config"

# Check if the entry already exists
if grep -q "Host juratminer" "$ssh_config"; then
    # Update the existing entry
    sed -i "/^Host juratminer/,+3s/^  HostName .*/  HostName $instance_ip/" "$ssh_config"
else
    # Add a new entry
    echo -e "\nHost juratminer\n  HostName $instance_ip\n  User admin\n  IdentityFile ~/.ssh/jurat_ec2_key.pem" >> "$ssh_config"
fi

echo "SSH configuration updated. You can now connect using 'ssh juratminer'."
