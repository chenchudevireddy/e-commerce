# Blue-Green Deployment Strategy for ShopHub E-Commerce

This guide explains how to implement and use blue-green deployments for your Angular e-commerce application on Amazon EKS.

## 🎯 What is Blue-Green Deployment?

Blue-green deployment is a deployment strategy that reduces downtime and risk by running two identical production environments called Blue and Green. At any time, only one of the environments is live, serving all production traffic. The other environment remains idle, ready to be switched to if needed.

### Benefits
- **Zero-downtime deployments**: Switch traffic instantly between environments
- **Instant rollback**: Switch back to the previous version immediately if issues occur
- **Reduced risk**: Test the new version thoroughly before going live
- **Simplified rollback**: No need to redeploy previous versions

## 📁 Blue-Green Architecture

```
Production Traffic → Load Balancer → Active Environment (Blue/Green)
                                      ↓
Preview Traffic → Load Balancer → Inactive Environment (Green/Blue)
```

### Components
- **Blue Deployment**: Current production environment
- **Green Deployment**: Staging environment for testing new releases
- **Services**: Route traffic to active environment
- **Ingress**: Handle external traffic routing
- **Preview Service**: Allow testing of inactive environment

## 🚀 Quick Start

### 1. Initial Setup (Blue Environment)

```bash
# Deploy initial blue environment
./deploy.sh \
  --registry=123456789012.dkr.ecr.us-east-1.amazonaws.com \
  --repo=ecommerce-app \
  --tag=v1.0.0 \
  --cluster=my-eks-cluster \
  --strategy=blue-green \
  --domain=myapp.example.com
```

### 2. Deploy New Version (Green Environment)

```bash
# Deploy v2.0.0 to green environment
./blue-green-deploy.sh deploy 123456789012.dkr.ecr.us-east-1.amazonaws.com/ecommerce-app:v2.0.0
```

### 3. Test Green Environment

```bash
# Check deployment status
./blue-green-deploy.sh status

# Validate green environment
./validate-deployment.sh green https://preview.myapp.example.com
```

### 4. Switch Traffic to Green

```bash
# Switch production traffic to green
./blue-green-deploy.sh switch green
```

## 📋 Detailed Workflow

### Step 1: Deploy to Inactive Environment

```bash
# Deploy new version to inactive environment (green if blue is active)
./blue-green-deploy.sh deploy your-registry.com/ecommerce-app:v2.0.0 --namespace ecommerce
```

This will:
- Identify the inactive environment (green)
- Scale up the green deployment
- Update the image to the new version
- Wait for the deployment to be ready
- Run validation checks

### Step 2: Test the Deployment

```bash
# Check overall status
./blue-green-deploy.sh status

# Validate the inactive environment
./validate-deployment.sh green https://preview.myapp.example.com comprehensive

# Run performance tests
./validate-deployment.sh green https://preview.myapp.example.com performance
```

### Step 3: Switch Traffic

```bash
# Switch production traffic to the new version
./blue-green-deploy.sh switch green
```

This will:
- Update the service selector to point to green
- Wait for traffic to stabilize
- Run post-switch validation
- Scale down the old environment (blue)

### Step 4: Monitor and Rollback (if needed)

```bash
# Monitor the deployment
./blue-green-deploy.sh status

# If issues occur, rollback immediately
./blue-green-deploy.sh rollback
```

## 🔧 Configuration Files

### Deployment Manifests
- **`k8s/deployment-blue-green.yaml`**: Separate deployments for blue and green
- **`k8s/service-blue-green.yaml`**: Services with color-based selectors
- **`k8s/ingress-blue-green.yaml`**: Ingress with preview subdomain support
- **`k8s/config-blue-green.yaml`**: Configuration and version tracking

### Scripts
- **`blue-green-deploy.sh`**: Main blue-green deployment script
- **`validate-deployment.sh`**: Comprehensive validation script
- **`deploy.sh`**: Updated to support blue-green strategy

## 🎛️ Available Commands

### Blue-Green Deployment Script

```bash
# Deploy new version
./blue-green-deploy.sh deploy IMAGE [OPTIONS]

# Switch traffic to specific color
./blue-green-deploy.sh switch COLOR

# Rollback to previous version
./blue-green-deploy.sh rollback

# Show deployment status
./blue-green-deploy.sh status

# Show help
./blue-green-deploy.sh --help
```

### Validation Script

```bash
# Comprehensive validation
./validate-deployment.sh COLOR BASE_URL [CHECK_TYPE]

# Examples
./validate-deployment.sh green https://preview.myapp.com comprehensive
./validate-deployment.sh blue https://myapp.com k8s
./validate-deployment.sh green https://preview.myapp.com performance
```

## 🔍 Validation Types

### Comprehensive Validation
- Kubernetes resource health
- HTTP endpoint availability
- Application health checks
- Database connectivity (if applicable)

### Kubernetes Validation
- Deployment status and replicas
- Pod health and status
- Resource availability

### HTTP Validation
- Health check endpoints
- Application page loads
- API endpoint responses

### Performance Validation
- Load testing with Apache Bench
- Response time metrics
- Error rate monitoring

## 🌐 URL Structure

### Production URLs
- **Main Application**: `https://your-domain.com`
- **Health Check**: `https://your-domain.com/health`

### Preview URLs
- **Preview Application**: `https://preview.your-domain.com`
- **Preview Health**: `https://preview.your-domain.com/health`

## 📊 Monitoring Blue-Green Deployments

### Check Active Environment
```bash
# Get current active color
kubectl get configmap blue-green-config -n ecommerce -o jsonpath='{.data.active-color}'

# Check service selector
kubectl get service ecommerce-app-service -n ecommerce -o jsonpath='{.spec.selector.color}'
```

### Monitor Traffic Distribution
```bash
# Check pod distribution
kubectl get pods -n ecommerce -l app=ecommerce-app -o custom-columns="NAME:.metadata.name,COLOR:.metadata.labels.color,STATUS:.status.phase"

# Check deployment status
kubectl get deployments -n ecommerce -l app=ecommerce-app
```

### View Logs
```bash
# Logs from active environment
kubectl logs -f deployment/ecommerce-app-blue -n ecommerce

# Logs from preview environment
kubectl logs -f deployment/ecommerce-app-green -n ecommerce
```

## 🚨 Rollback Procedures

### Automatic Rollback
The blue-green script automatically rolls back if validation fails after traffic switch.

### Manual Rollback
```bash
# Immediate rollback to previous version
./blue-green-deploy.sh rollback

# Check rollback status
./blue-green-deploy.sh status
```

### Emergency Rollback
```bash
# Force switch to specific environment
kubectl patch service ecommerce-app-service -n ecommerce --type merge -p '{"spec":{"selector":{"color":"blue"}}}'
```

## 🔒 Security Considerations

### Network Policies
Blue-green deployments include network policies to isolate environments:
- Traffic isolation between blue and green
- Controlled access to preview environment
- Security group rules for load balancers

### Access Control
- Preview environment accessible only for testing
- Production environment secured with SSL/TLS
- IAM roles for deployment automation

## 📈 Scaling Blue-Green Deployments

### Horizontal Scaling
```bash
# Scale active environment
kubectl scale deployment ecommerce-app-blue --replicas=10 -n ecommerce

# Scale preview environment for load testing
kubectl scale deployment ecommerce-app-green --replicas=5 -n ecommerce
```

### Auto Scaling
The HPA (Horizontal Pod Autoscaler) automatically scales based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)
- Custom metrics (if configured)

## 🔄 CI/CD Integration

### GitHub Actions Example
```yaml
# .github/workflows/blue-green-deploy.yml
name: Blue-Green Deployment

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Deploy to inactive environment
      run: |
        ./blue-green-deploy.sh deploy ${{ secrets.ECR_REGISTRY }}/ecommerce-app:${{ github.sha }}

    - name: Validate deployment
      run: |
        ./validate-deployment.sh green https://preview.myapp.com comprehensive

    - name: Switch traffic
      run: |
        ./blue-green-deploy.sh switch green

    - name: Post-deployment validation
      run: |
        ./validate-deployment.sh green https://myapp.com comprehensive
```

## 🐛 Troubleshooting

### Common Issues

**Traffic not switching:**
```bash
# Check service selector
kubectl get service ecommerce-app-service -n ecommerce -o yaml

# Check pod labels
kubectl get pods -n ecommerce -l app=ecommerce-app --show-labels
```

**Preview environment not accessible:**
```bash
# Check ingress configuration
kubectl get ingress -n ecommerce

# Check DNS resolution
nslookup preview.your-domain.com
```

**Validation failures:**
```bash
# Check pod logs
kubectl logs -f deployment/ecommerce-app-green -n ecommerce

# Check service endpoints
kubectl get endpoints -n ecommerce
```

### Debug Commands
```bash
# Check all resources
kubectl get all -n ecommerce -l app=ecommerce-app

# Check events
kubectl get events -n ecommerce --sort-by=.metadata.creationTimestamp

# Check ingress controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

## 📚 Best Practices

### Deployment Practices
1. **Always test in preview**: Validate thoroughly before switching traffic
2. **Monitor after switch**: Watch metrics for at least 30 minutes post-switch
3. **Keep old environment**: Don't scale down immediately after switch
4. **Automate validation**: Use scripts for consistent validation
5. **Document changes**: Track what changed in each deployment

### Environment Management
1. **Version tracking**: Use ConfigMaps to track deployed versions
2. **Resource limits**: Set appropriate CPU/memory limits
3. **Health checks**: Implement comprehensive health checks
4. **Backup strategy**: Ensure database backups before major deployments

### Security Practices
1. **Access control**: Limit who can trigger deployments
2. **Audit logging**: Log all deployment activities
3. **SSL/TLS**: Always use HTTPS for production
4. **Network isolation**: Use network policies to isolate environments

## 🎯 Advanced Features

### Canary Deployments
Combine blue-green with canary deployments for gradual traffic shifting.

### Automated Testing
Integrate automated tests that run against the preview environment.

### Feature Flags
Use feature flags to enable/disable features independently of deployments.

### Database Migrations
Handle database schema changes safely with blue-green deployments.

---

## 📞 Support

For issues with blue-green deployments:
1. Check the troubleshooting section above
2. Review Kubernetes logs and events
3. Validate network connectivity and DNS
4. Check AWS Load Balancer configuration

**Happy Deploying! 🚀**