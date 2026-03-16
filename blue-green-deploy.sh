#!/bin/bash

# Blue-Green Deployment Script for ShopHub E-Commerce
# This script manages blue-green deployments with zero-downtime switching

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-ecommerce}"
APP_NAME="ecommerce-app"
TIMEOUT="${TIMEOUT:-300}"
VALIDATION_URL="${VALIDATION_URL:-}"

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

log_deployment() {
    echo -e "${PURPLE}[DEPLOY]${NC} $1"
}

# Get current active color
get_active_color() {
    local selector=$(kubectl get service $APP_NAME-service -n $NAMESPACE -o jsonpath='{.spec.selector.color}' 2>/dev/null)
    echo "$selector"
}

# Get inactive color
get_inactive_color() {
    local active=$(get_active_color)
    if [[ "$active" == "blue" ]]; then
        echo "green"
    else
        echo "blue"
    fi
}

# Check if deployment is ready
check_deployment_ready() {
    local deployment=$1
    local timeout=$2

    log_info "Waiting for deployment $deployment to be ready..."
    kubectl wait --for=condition=available --timeout=${timeout}s deployment/$deployment -n $NAMESPACE

    # Check if all pods are ready
    local ready_pods=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    local total_pods=$(kubectl get deployment $deployment -n $NAMESPACE -o jsonpath='{.status.replicas}')

    if [[ "$ready_pods" == "$total_pods" ]]; then
        log_success "Deployment $deployment is ready ($ready_pods/$total_pods pods)"
        return 0
    else
        log_error "Deployment $deployment is not ready ($ready_pods/$total_pods pods)"
        return 1
    fi
}

# Validate deployment health
validate_deployment() {
    local color=$1
    local preview_service="$APP_NAME-preview"

    if [[ -n "$VALIDATION_URL" ]]; then
        log_info "Validating $color deployment via external URL: $VALIDATION_URL"

        # Wait for ingress to be ready
        sleep 10

        # Perform health check
        local max_attempts=10
        local attempt=1

        while [[ $attempt -le $max_attempts ]]; do
            if curl -f -s --max-time 10 "$VALIDATION_URL/health" > /dev/null 2>&1; then
                log_success "$color deployment validation passed"
                return 0
            fi

            log_warning "Validation attempt $attempt/$max_attempts failed, retrying..."
            sleep 5
            ((attempt++))
        done

        log_error "$color deployment validation failed after $max_attempts attempts"
        return 1
    else
        log_info "No validation URL provided, skipping external validation"
        return 0
    fi
}

# Switch traffic to specified color
switch_traffic() {
    local target_color=$1
    local active_color=$(get_active_color)

    log_deployment "Switching traffic from $active_color to $target_color"

    # Update main service selector
    kubectl patch service $APP_NAME-service -n $NAMESPACE --type merge -p "{\"spec\":{\"selector\":{\"color\":\"$target_color\"}}}"

    # Update load balancer service if it exists
    kubectl patch service $APP_NAME-lb -n $NAMESPACE --type merge -p "{\"spec\":{\"selector\":{\"color\":\"$target_color\"}}}" 2>/dev/null || true

    log_success "Traffic switched to $target_color deployment"
}

# Scale deployment
scale_deployment() {
    local deployment=$1
    local replicas=$2

    log_info "Scaling $deployment to $replicas replicas"
    kubectl scale deployment $deployment --replicas=$replicas -n $NAMESPACE
}

# Deploy to inactive environment
deploy_to_inactive() {
    local image=$1
    local inactive_color=$(get_inactive_color)
    local deployment="$APP_NAME-$inactive_color"

    log_deployment "Deploying to $inactive_color environment"

    # Update deployment image
    kubectl set image deployment/$deployment $APP_NAME=$image -n $NAMESPACE

    # Scale up the inactive deployment
    scale_deployment $deployment 3

    # Wait for deployment to be ready
    if ! check_deployment_ready $deployment $TIMEOUT; then
        log_error "Deployment $deployment failed to become ready"
        return 1
    fi

    # Validate the deployment
    if ! validate_deployment $inactive_color; then
        log_error "Deployment validation failed for $inactive_color"
        scale_deployment $deployment 0
        return 1
    fi

    log_success "Successfully deployed to $inactive_color environment"
    echo "$inactive_color"
}

# Perform blue-green deployment
blue_green_deploy() {
    local image=$1
    local active_color=$(get_active_color)
    local inactive_color=$(get_inactive_color)

    log_deployment "Starting blue-green deployment"
    log_info "Active environment: $active_color"
    log_info "Target environment: $inactive_color"
    log_info "Image: $image"

    # Deploy to inactive environment
    local deployed_color
    if ! deployed_color=$(deploy_to_inactive "$image"); then
        log_error "Failed to deploy to inactive environment"
        exit 1
    fi

    # Switch traffic
    switch_traffic "$deployed_color"

    # Wait a bit for traffic to stabilize
    log_info "Waiting for traffic to stabilize..."
    sleep 30

    # Validate after switch
    if ! validate_deployment "$deployed_color"; then
        log_error "Post-switch validation failed. Rolling back..."

        # Rollback: switch back to previous active
        switch_traffic "$active_color"
        scale_deployment "$APP_NAME-$deployed_color" 0

        log_error "Rollback completed. Traffic switched back to $active_color"
        exit 1
    fi

    # Scale down old deployment
    log_info "Scaling down old $active_color deployment"
    scale_deployment "$APP_NAME-$active_color" 0

    log_success "Blue-green deployment completed successfully!"
    log_info "Active environment is now: $deployed_color"
}

# Rollback to previous version
rollback() {
    local active_color=$(get_active_color)
    local inactive_color=$(get_inactive_color)

    log_warning "Rolling back to $inactive_color environment"

    # Check if inactive deployment exists and is ready
    local inactive_deployment="$APP_NAME-$inactive_color"
    local ready_replicas=$(kubectl get deployment $inactive_deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")

    if [[ "$ready_replicas" == "0" ]]; then
        log_error "Cannot rollback: $inactive_color environment has no ready replicas"
        exit 1
    fi

    # Switch traffic back
    switch_traffic "$inactive_color"

    # Scale up the rollback target
    scale_deployment "$inactive_deployment" 3

    # Scale down current active
    scale_deployment "$APP_NAME-$active_color" 0

    log_success "Rollback completed. Active environment: $inactive_color"
}

# Show status
show_status() {
    log_info "Blue-Green Deployment Status"
    echo "================================"

    local active_color=$(get_active_color)
    echo "Active Environment: $active_color"

    echo ""
    echo "Deployments:"
    kubectl get deployments -n $NAMESPACE -l app=$APP_NAME -o custom-columns="NAME:.metadata.name,READY:.status.readyReplicas,DESIRED:.status.replicas,IMAGE:.spec.template.spec.containers[0].image"

    echo ""
    echo "Services:"
    kubectl get services -n $NAMESPACE -l app=$APP_NAME -o custom-columns="NAME:.metadata.name,TYPE:.spec.type,SELECTOR:.spec.selector.color"

    echo ""
    echo "Ingress:"
    kubectl get ingress -n $NAMESPACE -l app=$APP_NAME
}

# Show help
show_help() {
    cat << EOF
Blue-Green Deployment Script for ShopHub E-Commerce

USAGE:
    ./blue-green-deploy.sh [COMMAND] [OPTIONS]

COMMANDS:
    deploy IMAGE    Perform blue-green deployment with specified image
    rollback        Rollback to previous environment
    status          Show current deployment status
    switch COLOR    Manually switch traffic to specified color (blue/green)

OPTIONS:
    --namespace NS  Kubernetes namespace (default: ecommerce)
    --timeout SEC   Timeout for deployment readiness (default: 300)
    --validation-url URL  URL for validation checks
    --help, -h      Show this help message

EXAMPLES:
    # Deploy new version
    ./blue-green-deploy.sh deploy myregistry.com/app:v2.0.0

    # Deploy with validation
    ./blue-green-deploy.sh deploy myregistry.com/app:v2.0.0 --validation-url https://preview.myapp.com

    # Rollback
    ./blue-green-deploy.sh rollback

    # Check status
    ./blue-green-deploy.sh status

    # Manual switch
    ./blue-green-deploy.sh switch green

EOF
}

# Main function
main() {
    case "${1:-}" in
        deploy)
            if [[ -z "${2:-}" ]]; then
                log_error "Image is required for deploy command"
                echo "Usage: $0 deploy IMAGE [OPTIONS]"
                exit 1
            fi
            blue_green_deploy "$2"
            ;;
        rollback)
            rollback
            ;;
        status)
            show_status
            ;;
        switch)
            if [[ -z "${2:-}" ]]; then
                log_error "Color is required for switch command"
                echo "Usage: $0 switch COLOR (blue or green)"
                exit 1
            fi
            if [[ "$2" != "blue" && "$2" != "green" ]]; then
                log_error "Color must be 'blue' or 'green'"
                exit 1
            fi
            switch_traffic "$2"
            ;;
        --help|-h|"")
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

# Parse additional arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        --validation-url)
            VALIDATION_URL="$2"
            shift 2
            ;;
        deploy|rollback|status|switch|--help|-h)
            # These are handled by main()
            break
            ;;
        *)
            shift
            ;;
    esac
done

# Run main function
main "$@"