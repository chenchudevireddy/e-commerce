# ShopHub E-Commerce - EKS Deployment Guide

This guide provides complete instructions for deploying the Angular e-commerce application to Amazon EKS (Elastic Kubernetes Service).

## 📋 Prerequisites

### Required Tools
- **Docker** (v20.10+)
- **kubectl** (v1.24+)
- **AWS CLI** (v2.0+)
- **eksctl** (optional, for cluster creation)
- **Git** (for cloning repositories)

### AWS Resources Required
- **EKS Cluster** (Kubernetes 1.24+)
- **ECR Repository** (for Docker images)
- **VPC and Subnets** (for EKS networking)
- **IAM Roles** (for EKS service accounts)
- **Load Balancer** (ALB/NLB for external access)

### Required Permissions
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*",
                "ecr:*",
                "ec2:*",
                "iam:*",
                "elasticloadbalancing:*"
            ],
            "Resource": "*"
        }
    ]
}
```

## 🚀 Quick Deployment

### Option 1: Rolling Deployment (Default)

```bash
# Make the deployment script executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh \
  --registry=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --repo=ecommerce-app \
  --tag=v1.0.0 \
  --cluster=my-eks-cluster \
  --region=us-east-1 \
  --namespace=ecommerce \
  --domain=myapp.example.com
```

### Option 2: Blue-Green Deployment (Recommended for Production)

```bash
# Initial deployment
./deploy.sh \
  --registry=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --repo=ecommerce-app \
  --tag=v1.0.0 \
  --cluster=my-eks-cluster \
  --strategy=blue-green \
  --domain=myapp.example.com

# Deploy new version to inactive environment
./blue-green-deploy.sh deploy 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app:v2.0.0

# Test the preview environment
./validate-deployment.sh green https://preview.myapp.example.com

# Switch production traffic
./blue-green-deploy.sh switch green
```

### Option 3: Manual Deployment

```bash
# 1. Build and push Docker image
docker build -t your-registry/ecommerce-app:latest .
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin your-registry
docker push your-registry/ecommerce-app:latest

# 2. Update Kubernetes manifests
sed -i 's|your-registry/ecommerce-app:latest|your-actual-registry/ecommerce-app:v1.0.0|g' k8s/deployment.yaml
sed -i 's|your-domain.com|your-actual-domain.com|g' k8s/ingress.yaml

# 3. Deploy to Kubernetes
kubectl create namespace ecommerce
kubectl apply -f k8s/config.yaml -n ecommerce
kubectl apply -f k8s/policies.yaml -n ecommerce
kubectl apply -f k8s/deployment.yaml -n ecommerce
kubectl apply -f k8s/service.yaml -n ecommerce
kubectl apply -f k8s/ingress.yaml -n ecommerce

# 4. Check deployment status
kubectl get pods -n ecommerce
kubectl get services -n ecommerce
kubectl get ingress -n ecommerce
```

## 📁 Project Structure

```
e-commerce/
├── Dockerfile              # Multi-stage Docker build
├── nginx.conf              # Nginx configuration for SPA
├── .dockerignore           # Docker build optimization
├── deploy.sh               # Automated deployment script (rolling & blue-green)
├── blue-green-deploy.sh    # Blue-green deployment management
├── validate-deployment.sh  # Deployment validation script
├── k8s/                    # Kubernetes manifests
│   ├── deployment.yaml     # Rolling deployment
│   ├── service.yaml        # Services for rolling deployment
│   ├── ingress.yaml        # Ingress for rolling deployment
│   ├── config.yaml         # ConfigMaps, Secrets, HPA
│   ├── policies.yaml       # Network policies, PDB, quotas
│   ├── deployment-blue-green.yaml    # Blue-green deployments
│   ├── service-blue-green.yaml       # Blue-green services
│   ├── ingress-blue-green.yaml       # Blue-green ingress
│   └── config-blue-green.yaml        # Blue-green configuration
├── EKS_DEPLOYMENT_README.md         # This file
└── BLUE_GREEN_DEPLOYMENT_README.md  # Blue-green deployment guide
```

## 🔧 Configuration

### Environment Variables

Update the following in your deployment:

```yaml
# In k8s/deployment.yaml
env:
- name: NODE_ENV
  value: "production"
# Add your custom environment variables here
```

### Domain Configuration

```yaml
# In k8s/ingress.yaml
spec:
  rules:
  - host: your-domain.com  # Replace with your actual domain
```

### SSL/TLS Configuration

The ingress is configured for SSL redirection. To set up SSL:

1. **Using AWS Certificate Manager (ACM):**
   ```yaml
   # In k8s/ingress.yaml
   annotations:
     alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/certificate-id
   ```

2. **Using cert-manager:**
   ```yaml
   # Install cert-manager first
   kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

   # Then update ingress annotations
   annotations:
     cert-manager.io/cluster-issuer: "letsencrypt-prod"
   ```

## 🔍 Monitoring & Troubleshooting

### Check Application Health

```bash
# Check pod status
kubectl get pods -n ecommerce

# Check pod logs
kubectl logs -f deployment/ecommerce-app -n ecommerce

# Check service endpoints
kubectl get endpoints -n ecommerce

# Check ingress status
kubectl describe ingress ecommerce-app-ingress -n ecommerce
```

### Common Issues

**1. Image Pull Errors:**
```bash
# Check if image exists in ECR
aws ecr describe-images --repository-name ecommerce-app --region us-east-1

# Check ECR permissions
aws ecr get-login-password --region us-east-1
```

**2. Load Balancer Not Created:**
```bash
# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Verify IAM permissions for ALB controller
```

**3. Ingress Not Working:**
```bash
# Check ingress events
kubectl describe ingress ecommerce-app-ingress -n ecommerce

# Verify domain DNS configuration
nslookup your-domain.com
```

### Health Checks

The application includes health check endpoints:
- **Liveness Probe:** `/health` (HTTP 200)
- **Readiness Probe:** `/health` (HTTP 200)

## 📊 Scaling & Performance

### Horizontal Pod Autoscaler (HPA)

The deployment includes HPA configuration:
- **Min Replicas:** 2
- **Max Replicas:** 10
- **CPU Target:** 70%
- **Memory Target:** 80%

```bash
# Check HPA status
kubectl get hpa -n ecommerce

# View HPA details
kubectl describe hpa ecommerce-app-hpa -n ecommerce
```

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment ecommerce-app --replicas=5 -n ecommerce

# Update HPA settings
kubectl edit hpa ecommerce-app-hpa -n ecommerce
```

## 🔒 Security Best Practices

### Network Security
- **Network Policies:** Restrict pod-to-pod communication
- **Security Contexts:** Non-root user, read-only filesystem
- **Resource Limits:** CPU and memory limits enforced

### Image Security
- **Multi-stage Build:** Reduces attack surface
- **Non-root User:** Runs as nginx user (UID 101)
- **Minimal Base Image:** Uses Alpine Linux

### Secrets Management
```yaml
# Create secrets
kubectl create secret generic ecommerce-secrets \
  --from-literal=api-key=your-api-key \
  --from-literal=jwt-secret=your-jwt-secret \
  -n ecommerce
```

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
# .github/workflows/deploy.yml
name: Deploy to EKS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Login to Amazon ECR
      id: login-ecr
      uses: aws-actions/amazon-ecr-login@v1

    - name: Build and push Docker image
      run: |
        docker build -t ${{ steps.login-ecr.outputs.registry }}/ecommerce-app:${{ github.sha }} .
        docker push ${{ steps.login-ecr.outputs.registry }}/ecommerce-app:${{ github.sha }}

    - name: Deploy to EKS
      run: |
        aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
        sed -i 's|latest|${{ github.sha }}|g' k8s/deployment.yaml
        kubectl apply -f k8s/ -n ecommerce
```

## 📈 Monitoring & Logging

### CloudWatch Integration

```bash
# Enable CloudWatch logging for EKS control plane
aws eks update-cluster-config \
  --region us-east-1 \
  --name your-cluster-name \
  --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}'
```

### Application Monitoring

Consider adding:
- **Prometheus** for metrics collection
- **Grafana** for dashboards
- **AWS X-Ray** for distributed tracing
- **CloudWatch Logs** for centralized logging

## 🗑️ Cleanup

To remove the deployment:

```bash
# Delete all resources
kubectl delete -f k8s/ -n ecommerce

# Delete namespace
kubectl delete namespace ecommerce

# Delete ECR repository
aws ecr delete-repository --repository-name ecommerce-app --force --region us-east-1

# Delete load balancer (if created)
aws elbv2 delete-load-balancer --load-balancer-arn <load-balancer-arn>
```

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS EKS documentation
3. Check Kubernetes logs and events
4. Verify IAM permissions and network configuration

## � Blue-Green Deployment Strategy

For zero-downtime deployments with instant rollback capabilities, use the blue-green deployment strategy:

### Features
- **Zero-downtime deployments**: Switch traffic instantly between blue and green environments
- **Instant rollback**: Switch back to previous version immediately if issues occur
- **Preview environment**: Test new versions before going live
- **Automated validation**: Comprehensive health and performance checks

### Quick Start
```bash
# Initial setup
./deploy.sh --strategy=blue-green [other options]

# Deploy new version
./blue-green-deploy.sh deploy your-image:v2.0.0

# Test preview environment
./validate-deployment.sh green https://preview.your-domain.com

# Switch to production
./blue-green-deploy.sh switch green

# Check status
./blue-green-deploy.sh status
```

### Files
- **`BLUE_GREEN_DEPLOYMENT_README.md`**: Complete blue-green deployment guide
- **`blue-green-deploy.sh`**: Blue-green deployment management script
- **`validate-deployment.sh`**: Comprehensive validation script
- **`k8s/*-blue-green.yaml`**: Blue-green specific Kubernetes manifests

See `BLUE_GREEN_DEPLOYMENT_README.md` for detailed instructions.

---