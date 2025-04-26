provider "google" {
  project     = "atom-455906"
  region      = "us-central1"            # or your preferred region
  credentials = file("account-key.json") # Optional if using gcloud auth
}