# Create NFS server to test PV
gcloud filestore instances create nfs-server \
--project=$(gcloud config get-value project) \
--zone=$(gcloud config get-value compute/zone) \
--tier=STANDARD \
--file-share=name="vol1",capacity=1TB \
--network=name="kubernetes-cluster"
SHARE_IP = $(gcloud filestore instances describe nfs-server \
--project=$(gcloud config get-value project) \
--zone=$(gcloud config get-value compute/zone) \
--format 'value(networks[0].ipAddresses[0])')
SHARE_NAME = $(gcloud filestore instances describe nfs-server \
--project=$(gcloud config get-value project) \
--zone=$(gcloud config get-value compute/zone) \
--format 'value(fileShares[0].name)')
# Delete when not needed
gcloud filestore instances delete nfs-server \
--project=$(gcloud config get-value project) \
--zone=$(gcloud config get-value compute/zone)
