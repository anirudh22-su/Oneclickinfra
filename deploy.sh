#!/bin/bash

echo "🚀 Starting ONE-CLICK PostgreSQL deployment..."

cd terraform
PRIMARY=$(terraform output -raw primary_db_private_ip)
REPLICA=$(terraform output -raw replica_db_private_ip)
BASTION_A=$(terraform output -raw bastion_a_public_ip)
BASTION_B=$(terraform output -raw bastion_b_public_ip)
cd ..

SSH_CONFIG="/home/anirudh/.ssh/oneclick_config"
SSH_KEY="/home/anirudh/.ssh/oneclick.pem"

# Create SSH configuration with ProxyJump and disabled host key checking
cat > $SSH_CONFIG <<EOF
Host bastion_primary
  HostName ${BASTION_A}
  User ubuntu
  IdentityFile ${SSH_KEY}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host db_primary
  HostName ${PRIMARY}
  User ubuntu
  IdentityFile ${SSH_KEY}
  ProxyJump bastion_primary
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host bastion_replica
  HostName ${BASTION_B}
  User ubuntu
  IdentityFile ${SSH_KEY}
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host db_replica
  HostName ${REPLICA}
  User ubuntu
  IdentityFile ${SSH_KEY}
  ProxyJump bastion_replica
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF

chmod 600 $SSH_CONFIG

# Export SSH config to be used for Ansible
export ANSIBLE_SSH_COMMON_ARGS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -F $SSH_CONFIG"

# Generate Ansible inventory
cat > ansible/inventory.ini <<EOF
[db]
db_primary
db_replica
EOF

echo "📋 Inventory created. Running Ansible playbook..."

# Run PostgreSQL setup playbook
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml \
  --extra-vars "primary_ip=${PRIMARY} replica_ip=${REPLICA} repl_password=${REPL_PASS}"



echo "🎉 PostgreSQL installation complete!"
