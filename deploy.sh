#!/bin/bash

# ShopHub E-Commerce - EKS Deployment Script
# This script automates the deployment of the Angular e-commerce application to Amazon EKS

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REGISTRY=""
REPO="ecommerce-app"
TAG="latest"
CLUSTER=""
REGION="us-east-1"
NAMESPACE="ecommerce"
DOMAIN=""
DEPLOYMENT_STRATEGY="rolling"  # rolling or blue-green
SKIP_CHECKS=false

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
ShopHub E-Commerce - EKS Deployment Script

USAGE:
    ./deploy.sh [OPTIONS]

OPTIONS:
    --registry=REGISTRY        ECR registry URL (required)
    --repo=REPO                Repository name (default: ecommerce-app)
    --tag=TAG                  Image tag (default: latest)
    --cluster=CLUSTER          EKS cluster name (required)
    --region=REGION            AWS region (default: us-east-1)
    --namespace=NAMESPACE      Kubernetes namespace (default: ecommerce)
    --domain=DOMAIN            Domain name for ingress (required)
    --strategy=STRATEGY        Deployment strategy: rolling or blue-green (default: rolling)
    --skip-checks              Skip prerequisite checks
    --help, -h                 Show this help message

EXAMPLES:
    # Rolling deployment (default)
    ./deploy.sh \\
      --registry=123456789012.dkr.ecr.us-east-1.amazonaws.com \\
      --repo=ecommerce-app \\
      --tag=v1.0.0 \\
      --cluster=my-eks-cluster \\
      --region=us-east-1 \\
      --namespace=ecommerce \\
      --domain=myapp.example.com

    # Blue-green deployment
    ./deploy.sh \\
      --registry=123456789012.dkr.ecr.us-east-1.amazonaws.com \\
      --repo=ecommerce-app \\
      --tag=v2.0.0 \\
      --cluster=my-eks-cluster \\
      --strategy=blue-green \\
      --domain=myapp.example.com

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --registry=*)
            REGISTRY="${1#*=}"
            shift
            ;;
        --repo=*)
            REPO="${1#*=}"
            shift
            ;;
        --tag=*)
            TAG="${1#*=}"
            shift
            ;;
        --cluster=*)
            CLUSTER="${1#*=}"
            shift
            ;;
        --region=*)
            REGION="${1#*=}"
            shift
            ;;
        --namespace=*)
            NAMESPACE="${1#*=}"
            shift
            ;;
        --domain=*)
            DOMAIN="${1#*=}"
            shift
            ;;
        --strategy=*)
            DEPLOYMENT_STRATEGY="${1#*=}"
            shift
            ;;
        --skip-checks)
            SKIP_CHECKS=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$REGISTRY" ]]; then
    log_error "Registry is required. Use --registry=your-registry"
    exit 1
fi

if [[ -z "$CLUSTER" ]]; then
    log_error "EKS cluster name is required. Use --cluster=your-cluster"
    exit 1
fi

if [[ -z "$DOMAIN" ]]; then
    log_error "Domain name is required. Use --domain=your-domain.com"
    exit 1
fi

if [[ "$DEPLOYMENT_STRATEGY" != "rolling" && "$DEPLOYMENT_STRATEGY" != "blue-green" ]]; then
    log_error "Invalid deployment strategy: $DEPLOYMENT_STRATEGY. Use 'rolling' or 'blue-green'"
    exit 1
fi

# Prerequisites check
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if required tools are installed
    local tools=("docker" "kubectl" "aws")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is not installed or not in PATH"
            exit 1
        fi
    done

    # Check AWS CLI configuration
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured. Please run 'aws configure'"
        exit 1
    fi

    # Check if EKS cluster exists
    if ! aws eks describe-cluster --name "$CLUSTER" --region "$REGION" &> /dev/null; then
        log_error "EKS cluster '$CLUSTER' not found in region '$REGION'"
        exit 1
    fi

    # Check if ECR repository exists, create if not
    if ! aws ecr describe-repositories --repository-names "$REPO" --region "$REGION" &> /dev/null; then
        log_warning "ECR repository '$REPO' does not exist. Creating..."
        aws ecr create-repository --repository-name "$REPO" --region "$REGION" &> /dev/null
        log_success "ECR repository created"
    fi

    log_success "Prerequisites check passed"
}

# Build and push Docker image
build_and_push_image() {
    log_info "Building Docker image..."

    # Build the image
    docker build -t "$REGISTRY/$REPO:$TAG" .

    log_info "Pushing image to ECR..."

    # Login to ECR
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$REGISTRY"

    # Push the image
    docker push "$REGISTRY/$REPO:$TAG"

    log_success "Image pushed successfully: $REGISTRY/$REPO:$TAG"
}

# Update Kubernetes manifests
update_manifests() {
    log_info "Updating Kubernetes manifests..."

    if [[ "$DEPLOYMENT_STRATEGY" == "blue-green" ]]; then
        # Update blue-green manifests
        sed -i.bak "s|your-registry/ecommerce-app:latest|$REGISTRY/$REPO:$TAG|g" k8s/deployment-blue-green.yaml
        sed -i.bak "s|your-domain.com|$DOMAIN|g" k8s/ingress-blue-green.yaml
        sed -i.bak "s|preview.your-domain.com|preview.$DOMAIN|g" k8s/ingress-blue-green.yaml
    else
        # Update rolling deployment manifests
        sed -i.bak "s|your-registry/ecommerce-app:latest|$REGISTRY/$REPO:$TAG|g" k8s/deployment.yaml
        sed -i.bak "s|your-domain.com|$DOMAIN|g" k8s/ingress.yaml
    fi

    log_success "Manifests updated"
}

# Deploy using rolling strategy
deploy_rolling() {
    log_info "Deploying using rolling update strategy..."

    # Apply configurations in order
    local manifests=("config.yaml" "policies.yaml" "deployment.yaml" "service.yaml" "ingress.yaml")

    for manifest in "${manifests[@]}"; do
        log_info "Applying $manifest..."
        kubectl apply -f "k8s/$manifest" -n "$NAMESPACE"
    done

    log_success "Rolling deployment applied successfully"
}

# Deploy using blue-green strategy
deploy_blue_green() {
    log_info "Deploying using blue-green strategy..."

    # Apply blue-green configurations
    local manifests=("config-blue-green.yaml" "policies.yaml" "deployment-blue-green.yaml" "service-blue-green.yaml" "ingress-blue-green.yaml")

    for manifest in "${manifests[@]}"; do
        log_info "Applying $manifest..."
        kubectl apply -f "k8s/$manifest" -n "$NAMESPACE"
    done

    log_success "Blue-green deployment configuration applied successfully"

    # Use the blue-green deployment script for the actual deployment
    log_info "Running blue-green deployment..."
    chmod +x blue-green-deploy.sh
    ./blue-green-deploy.sh deploy "$REGISTRY/$REPO:$TAG" --namespace "$NAMESPACE"
}

# Wait for deployment to be ready
wait_for_deployment() {
    log_info "Waiting for deployment to be ready..."

    if [[ "$DEPLOYMENT_STRATEGY" == "blue-green" ]]; then
        # For blue-green, the blue-green script handles waiting
        log_info "Blue-green deployment script handles readiness checks"
    else
        # For rolling deployment, wait for the deployment
        kubectl rollout status deployment/ecommerce-app -n "$NAMESPACE" --timeout=300s
    fi
}

# Show deployment information
show_deployment_info() {
    log_info "Deployment Information:"
    echo ""
    echo "Namespace: $NAMESPACE"
    echo "Cluster: $CLUSTER"
    echo "Region: $REGION"
    echo "Image: $REGISTRY/$REPO:$TAG"
    echo "Domain: $DOMAIN"
    echo "Strategy: $DEPLOYMENT_STRATEGY"
    echo ""

    if [[ "$DEPLOYMENT_STRATEGY" == "blue-green" ]]; then
        # Show blue-green specific information
        log_info "Blue-Green Status:"
        ./blue-green-deploy.sh status --namespace "$NAMESPACE"
        echo ""
        log_info "Preview URL: https://preview.$DOMAIN"
    else
        # Show rolling deployment information
        log_info "Service Information:"
        kubectl get services -n "$NAMESPACE" -o wide
        echo ""

        log_info "Pod Information:"
        kubectl get pods -n "$NAMESPACE" -o wide
        echo ""
    fi

    log_success "Application deployed successfully!"
    log_info "Access your application at: https://$DOMAIN"
}

# Main deployment function
main() {
    log_info "Starting $DEPLOYMENT_STRATEGY deployment for ShopHub E-Commerce"
    echo "=================================================="

    if [[ "$SKIP_CHECKS" != true ]]; then
        check_prerequisites
    else
        log_warning "Skipping prerequisite checks"
    fi

    build_and_push_image
    update_manifests

    if [[ "$DEPLOYMENT_STRATEGY" == "blue-green" ]]; then
        deploy_blue_green
    else
        deploy_rolling
        wait_for_deployment
    fi

    show_deployment_info

    log_success "🎉 Deployment completed successfully!"
    log_info "Don't forget to:"
    log_info "  1. Configure DNS to point $DOMAIN to the load balancer"
    if [[ "$DEPLOYMENT_STRATEGY" == "blue-green" ]]; then
        log_info "  2. Test the preview environment at https://preview.$DOMAIN"
        log_info "  3. Run './blue-green-deploy.sh status' to check deployment status"
    fi
    log_info "  4. Set up SSL certificate if not using ACM"
    log_info "  5. Configure monitoring and logging as needed"
}

# Run main function
main "$@"