# Start hubble
cilium hubble ui --local-browser=false

# Port-forward to localhost:12000
gcloud compute ssh --ssh-flag="-L 12000:127.0.0.1:12000" controller
