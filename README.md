# Trendify – DevOps CI/CD Project

## Project Overview

Trendify is a React-based web application deployed on AWS EKS using a DevOps CI/CD pipeline.

This project demonstrates application containerization, infrastructure provisioning using Terraform, Docker image management, Kubernetes deployment, and automated CI/CD using Jenkins and GitHub Webhooks.

## GitHub Repository

[Trendify DevOps Project](https://github.com/SivaSakthi08/Trend-DevOps-Project)

## Docker Hub

Docker image: `sivasakthi08/trendify-app:1.0`

## Live Application

**Deployment URL:**

http://a92c55fbd05dc4d1dbaedc804b53ab1f-1387228542.ap-south-1.elb.amazonaws.com

The application is exposed through a Kubernetes LoadBalancer service on AWS.

## Technology Stack

- **Frontend:** React
- **Version Control:** Git and GitHub
- **Containerization:** Docker
- **Container Registry:** Docker Hub
- **Infrastructure as Code:** Terraform
- **Cloud Provider:** AWS
- **CI/CD:** Jenkins
- **Container Orchestration:** Kubernetes (Amazon EKS)
- **Web Server:** Nginx

## Project Architecture

1. Source code is maintained in GitHub.
2. A GitHub Webhook notifies Jenkins whenever code is pushed.
3. Jenkins checks out the latest source code.
4. Jenkins builds the Docker image.
5. The image is pushed to Docker Hub.
6. Jenkins deploys the application to Amazon EKS using Kubernetes manifests.
7. The application is exposed through a Kubernetes LoadBalancer service.

## Project Structure

```text
Trend-DevOps-Project/
│
├── Dockerfile
├── Jenkinsfile
├── .dockerignore
├── .gitignore
├── README.md
│
├── k8s/
│   ├── deployment.yaml
│   └── service.yaml
│
└── terraform/
    └── main.tf
```

## Application Setup

Clone the repository:

```bash
git clone https://github.com/SivaSakthi08/Trend-DevOps-Project.git
cd Trend-DevOps-Project
```

Install dependencies and build the React application:

```bash
npm install
npm run build
```

## Docker Setup

Build the Docker image:

```bash
docker build -t trendify-app:1.0 .
```

Run the container:

```bash
docker run -d -p 3000:80 --name trendify-container trendify-app:1.0
```

Access the application locally:

```text
http://localhost:3000
```

## Infrastructure Provisioning Using Terraform

Terraform is used to provision AWS infrastructure, including:

- Virtual Private Cloud (VPC)
- IAM roles and permissions
- EC2 instance for Jenkins

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Review the infrastructure plan:

```bash
terraform plan
```

Provision the infrastructure:

```bash
terraform apply
```

## Kubernetes Deployment

The application is deployed to Amazon EKS using Kubernetes Deployment and Service manifests.

Apply the Kubernetes configuration:

```bash
kubectl apply -f k8s/
```

Check deployment status:

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

The Kubernetes Service uses the LoadBalancer type to expose the application externally.

## Jenkins CI/CD Pipeline

A declarative Jenkins pipeline automates the deployment workflow.

### Pipeline Stages

1. **Verify Source Code** – Checks out the latest code from GitHub.
2. **Build Docker Image** – Builds the application container image.
3. **Push to Docker Hub** – Publishes the image to Docker Hub using Jenkins credentials.
4. **Deploy to EKS** – Applies Kubernetes manifests and verifies the deployment.

## GitHub Webhook Integration

GitHub Webhooks are configured to trigger the Jenkins pipeline automatically whenever changes are pushed to the repository.

The automatic trigger was tested successfully, and Jenkins reported the build cause:

`Started by GitHub push by sivasakthi`

## Deployment Verification

The following commands were used to verify the deployment:

```bash
kubectl get deployments,pods,services
```

The application was successfully deployed to Amazon EKS and accessed through its external LoadBalancer endpoint.

## Conclusion

This project demonstrates an end-to-end DevOps workflow using AWS, Terraform, Docker, Docker Hub, Kubernetes, Jenkins, and GitHub Webhooks.

The CI/CD pipeline automates the process from source code changes to container image creation and Kubernetes deployment.
GitHub webhook integration tested successfully.
