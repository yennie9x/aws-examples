
# Install AWS CLI v2
pwd=$(pwd)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
cd $pwd

# Install CDK CLI
npm install -g aws-cdk
cdk --version

# Install YARN
npm install -g yarn
yarn --version

# Install AWS Amplify
npm install -g @aws-amplify/cli

# Install Taskfiles
npm install -g @go-task/cli