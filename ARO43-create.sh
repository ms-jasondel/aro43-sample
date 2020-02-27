LOCATION=eastus
RESOURCEGROUP="jasondel-aro43"
CLUSTER=cluster

az group create -g "$RESOURCEGROUP" -l $LOCATION
az network vnet create \
  -g "$RESOURCEGROUP" \
  -n dev-vnet \
  --address-prefixes 10.0.0.0/9 \
  >/dev/null
for subnet in "$CLUSTER-master" "$CLUSTER-worker"; do
  az network vnet subnet create \
    -g "$RESOURCEGROUP" \
    --vnet-name dev-vnet \
    -n "$subnet" \
    --address-prefixes 10.$((RANDOM & 127)).$((RANDOM & 255)).0/24 \
    --service-endpoints Microsoft.ContainerRegistry \
    >/dev/null
done
az network vnet subnet update \
  -g "$RESOURCEGROUP" \
  --vnet-name dev-vnet \
  -n "$CLUSTER-master" \
  --disable-private-link-service-network-policies true \
  >/dev/null

# Create the cluster
az aro create \
  -g "$RESOURCEGROUP" \
  -n "$CLUSTER" \
  --vnet dev-vnet \
  --master-subnet "$CLUSTER-master" \
  --worker-subnet "$CLUSTER-worker" \
  --apiserver-visibility Private \
  --ingress-visibility Private \
  --domain aro.jasondel.com   

# Create a vnet that ARO will peer with
# az network vnet create \
#   -g "shared" \
#   -n "shared-vnet-172" \
#   --address-prefixes 172.20.0.0/24 \
#   >/dev/null

# az network vnet subnet create \
#     -g "shared" \
#     --vnet-name "shared-vnet-172" \
#     -n "shared-vnet-172-vm-subnet" \
#     --address-prefixes 172.20.0.128/25 \
#     >/dev/null


# Create a vnet that ARO will peer with
# az network vnet create \
#   -g "shared" \
#   -n shared-vnet \
#   --address-prefixes 192.168.1.0/24 \
#   >/dev/null

# az network vnet subnet create \
#     -g "shared" \
#     --vnet-name shared-vnet \
#     -n "SharedSubnet1" \
#     --address-prefixes 192.168.1.128/25 \
#     >/dev/null

# Deploy an RG that will contain a VM and VNET peering 
# that we can use to test with
# PEERGROUP=peer-test
# VMSUBNETID=$(az network vnet subnet show --vnet shared-vnet -o tsv -n SharedSubnet1 -g shared --query id)

# AROVNET=$(az network vnet show -n dev-vnet -g $RESOURCEGROUP -o tsv --query id)

# az group create -l eastus --name "$PEERGROUP"

# az vm create -n peer-vm \
#     -g "$PEERGROUP" \
#     --image UbuntuLTS \
#     --size Standard_B1ls \
#     --subnet $VMSUBNETID 

# # Pair each vnet to each other
# az network vnet peering create \
#     -n PeerSharedToARO \
#     -g "shared" \
#     --vnet-name "shared-vnet" \
#     --remote-vnet /subscriptions/34beb8b0-c6ad-4448-8486-8a24649143cf/resourceGroups/jasondel-aro43/providers/Microsoft.Network/virtualNetworks/dev-vnet \
#     --allow-vnet-access

# az network vnet peering create \
#     -n PeerAROToShared \
#     -g "$RESOURCEGROUP" \
#     --vnet-name dev-vnet \
#     --remote-vnet /subscriptions/34beb8b0-c6ad-4448-8486-8a24649143cf/resourceGroups/Shared/providers/Microsoft.Network/virtualNetworks/shared-vnet \
#     --allow-vnet-access

# Install Docker on VM
# sudo apt-get update
# sudo apt install docker.io
# sudo systemctl start docker
# sudo systemctl enable docker

# Run a simple docker image that has a webserver
# docker run --rm -p 80:80 yeasy/simple-web:latest