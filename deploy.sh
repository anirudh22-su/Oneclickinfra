#!/bin/bash

echo "🚀 Starting ONE-CLICK PostgreSQL deployment..."

cd terraform
PRIMARY=$(terraform output -raw primary_db_private_ip)
REPLICA=$(terraform output -raw replica_db_private_ip)
BASTION_A=$(terraform output -raw bastion_a_public_ip)
BASTION_B=$(terraform output -raw bastion_b_public_ip)
cd ..

SSH_CONFIG=/home/anirudh/.ssh/oneclick_config

# Create SSH config for no-interaction and jump host
cat > $SSH_CONFIG <<EOF
Host bastion_primary
  HostName ${BASTION_A}
  User ubuntu
  IdentityFile /home/anirudh/.ssh/oneclick.pem

Host primary
  HostName ${PRIMARY}
  User ubuntu
  IdentityFile /home/anirudh/.ssh/oneclick.pem
  ProxyJump bastion_primary

Host bastion_replica
  HostName ${BASTION_B}
  User ubuntu
  IdentityFile /home/anirudh/.ssh/oneclick.pem

Host replica
  HostName ${REPLICA}
  User ubuntu
  IdentityFile /home/anirudh/.ssh/oneclick.pem
  ProxyJump bastion_replica
EOF

chmod 600 $SSH_CONFIG

# Force Ansible to use this SSH config
export ANSIBLE_SSH_COMMON_ARGS="-o StrictHostKeyChecking=no -F $SSH_CONFIG"

# Create inventory using aliases
cat > ansible/inventory.ini <<EOF
[primary]
primary

[replica]
replica

[db:children]
primary
replica
EOF

echo "📋 Inventory created. Running Ansible playbook..."

ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

echo "🎉 PostgreSQL setup done! You can now SSH as:"
echo "  👉 ssh -F ~/.ssh/oneclick_config primary"
echo "  👉 ssh -F ~/.ssh/oneclick_config replica"
