#!/bin/bash

echo -e "\e[44;37m"
echo "      _                 _     __  __ _                   ____       _               "
echo "     | |_   _ _ __ __ _| |_  |  \/  (_)_ __   ___ _ __  / ___|  ___| |_ _   _ _ __  "
echo "  _  | | | | | '__/ _| | __| | |\/| | | '_ \ / _ \ '__| \___ \ / _ \ __| | | | '_ \ "
echo " | |_| | |_| | | | (_| | |_  | |  | | | | | |  __/ |     ___) |  __/ |_| |_| | |_) |"
echo "  \___/ \__,_|_|  \__,_|\__| |_|  |_|_|_| |_|\___|_|    |____/ \___|\__|\__,_| .__/ "
echo "                                                                             |_|    "
echo -e "\e[0m"

echo "Please read the following Terms of Use carefully before proceeding."

less << 'EOT'
Acknowledgement by JTC Miner

1. Do not trade JTC on Bitmart. Bitmart is not a U.S.-based exchange and does not allow trading by U.S. residents. Bitmart has a geofence to intercept U.S. IP addresses but sometimes people use VPNs and sign up with a false address to circumvent Bitmart’s restrictions. Please be sure not to do so, as it is fraudulent and would be illegal.
In the early going, before there is much demand, Jurat is required to make a market in the JTC coin using our own funds. We have retained a market maker firm to do this service. If you were to use Bitmart as a U.S. resident, you could be transacting with our market maker’s bids and asks and that could subject these transactions to the jurisdiction of the SEC. Once JTC trading volume builds we will be able to apply to list on U.S.-based sites like Coinbase which do accept U.S. customers and do not require Jurat to make the market.

2. We will be expanding the community of miners. You are one of the early miners, and there were not many of them. The mining community will soon expand substantially expand beyond the 20-30 miners that you have been competing with at any given time. Expanding the number of miners makes the network more decentralized and adds new stakeholders in JTC’s success, all of which are good for the value of the coin. We have already received hundreds of requests to join and expect that these requests will pick up once the coin starts trading.
As we expand the community, the difficulty to mine a coin, and thus your cost per coin, will increase proportionally. For example, if the mining community increased from 20 miners to 200, the difficulty to mine a coin would increase 10x, as will the mining cost per coin. Put differently, the $150 or so in monthly fees you have been paying to AWS would buy you only 1/10th of the coins you have been earning each month. In the long run we expect that mining competition will expand to the point where the cost to mine a coin and the price of the coin will converge.
You have had the opportunity to mine and bank coins at a difficulty/cost that could be orders of magnitude less than the cost in the future. We hope that this opportunity will prove to have been very lucrative for you. We also hope and expect that mining will remain profitable for some time despite the coming increase in difficulty.
   
3. JTC mining remains by permission only. You have been given permission to mine JTC and we have provided you a non-transferrable license to use the JTC mining software to operate a single node. You are not permitted to operate more than one node nor to copy the software or transfer the software to a different server.
It is also important that you not give any-third party access to the software because the third-party could then copy the software and begin mining even though they may not have received our permission to mine.

4. Participation is at will. Either you or we can opt to part ways at any time for any reason. If you or we so elect, your license to use the software will terminate immediately and you must delete your copy of the software and deactivate your miner. Any coins that you have earned up to that time will remain yours.

5. You may not alter the software nor the environment in which you run the software. For example, you may not remove or change any function of the software, nor may you run it in a way that increases the hashing power of your node. Any such alterations could damage the network, adversely impact its environmental footprint, and unfairly advantage you at the expense of your fellow miners. At no time may you increase the hashing capacity of the server on which we installed your miner or switch to another method such as an ASIC miner.

6. From time-to-time we may make updates to the software. When we do so, the foregoing requirements will continue to apply.
You will also be responsible to update your node with the new software as it is made available. Through customer support, we will assist you and attempt to minimize the difficulty for you. In general, we will provide at least a 30-day window for installing an update. However, it is possible that an emergency could arise that requires an urgent update and your immediate attention.
If you fail to update your copy of the software, you may lose the ability to continue successfully mining.
At some point we may make the mining software open source, allowing miners to join without permission, as is the case with BTC mining. If that occurs, you will be relieved of the current license restrictions and the open-source license will apply.
     
7. You must disclose information to us and keep your disclosures up to date. We expect and require you to disclose to us your nationality, law licensure, current contact information and address, as well as the public key (wallet address) of your miner and the IP address of your node. Please ensure that we have your most current information. If any of this information changes, you will need to inform us directly. We may need to collect additional information from you in the future in which you will need to supply the information to continue mining.

8. Do not manipulate markets. Be aware that you likely possess a very substantial amount of JTC as compared to the average holder. So much so that your holdings, or even a modest percentage, may be sufficient to materially move the markets, particularly at this time. We have not and will not provide advice to you about your legal responsibilities when trading JTC. Each exchange that lists the coin may impose its own requirements in addition to whatever background law may apply.

9. Do not trade on non-public information. We do not believe that we have provided you any material non-public information about Jurat or the JTC coin. Nevertheless, we cannot guaranty that that is the case. To the extent you have concerns that you possess such information, whether through us or others, please reach out to us before trading the coin so that we can better understand the issue and determine how best to proceed.

I have read and agree to the forgoing terms of use.


(Press 'q' to exit the Terms of Use and Continue)
EOT

# Ask for user agreement
while true; do
    read -p "Do you agree to the Terms of Use? (yes/no) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) echo "You must agree to the Terms of Use to proceed with the installation."; exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo ""

if [ -d ".git" ]; then
    git pull
else
    git clone https://github.com/jurat-systems/jurat-miner-terraform.git
fi
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
    else
        echo "Key-pair already exists at $key_path. Skipping..."
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
export aws_region="us-east-2"

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

# Initialize Terraform
terraform init

# Import key pair and security group if they exist
terraform import aws_key_pair.jurat_key_pair jurat_key || true

security_groups_json=$(aws ec2 describe-security-groups --query "SecurityGroups[*].{ID:GroupId,Name:GroupName}" --output json)

# Use jq to parse JSON and extract the Group ID of jurat-sg
jurat_sg_id=$(echo "$security_groups_json" | jq -r '.[] | select(.Name=="jurat-sg") | .ID')

# Check if the jurat-sg ID was found
if [ -n "$jurat_sg_id" ]; then
    echo "Security Group ID of jurat-sg: $jurat_sg_id"
else
    echo "jurat-sg not found."
fi

terraform import aws_security_group.jurat_sg $jurat_sg_id || true

# Create the resources
terraform apply -auto-approve


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
