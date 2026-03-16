#!/bin/bash

# Blue-Green Deployment Validation Script
# This script validates deployments before and after blue-green switches

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="${NAMESPACE:-ecommerce}"
APP_NAME="ecommerce-app"
TIMEOUT="${TIMEOUT:-30}"
RETRIES="${RETRIES:-3}"

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

# Validate HTTP endpoint
validate_http_endpoint() {
    local url=$1
    local expected_status="${2:-200}"
    local timeout=$TIMEOUT

    log_info "Validating HTTP endpoint: $url (expected status: $expected_status)"

    local response
    local http_code

    # Use curl to check the endpoint
    response=$(curl -s -w "HTTPSTATUS:%{http_code}" --max-time $timeout "$url" 2>/dev/null)
    http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

    if [[ "$http_code" == "$expected_status" ]]; then
        log_success "HTTP validation passed: $url returned $http_code"
        return 0
    else
        log_error "HTTP validation failed: $url returned $http_code (expected $expected_status)"
        return 1
    fi
}

# Validate application health
validate_app_health() {
    local color=$1
    local base_url=$2

    log_info "Validating application health for $color environment"

    # Health check endpoint
    if ! validate_http_endpoint "$base_url/health" "200"; then
        return 1
    fi

    # Application-specific checks
    # Check if main page loads
    if ! validate_http_endpoint "$base_url/" "200"; then
        return 1
    fi

    # Check API endpoints if they exist
    if curl -s --max-time 5 "$base_url/api/products" > /dev/null 2>&1; then
        if ! validate_http_endpoint "$base_url/api/products" "200"; then
            log_warning "API endpoint validation failed, but continuing..."
        fi
    fi

    log_success "Application health validation passed for $color environment"
    return 0
}

# Validate Kubernetes resources
validate_k8s_resources() {
    local color=$1

    log_info "Validating Kubernetes resources for $color environment"

    local deployment="$APP_NAME-$color"

    # Check if deployment exists
    if ! kubectl get deployment "$deployment" -n "$NAMESPACE" > /dev/null 2>&1; then
        log_error "Deployment $deployment does not exist"
        return 1
    fi

    # Check deployment status
    local ready_replicas=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
    local desired_replicas=$(kubectl get deployment "$deployment" -n "$NAMESPACE" -o jsonpath='{.status.replicas}')

    if [[ "$ready_replicas" != "$desired_replicas" ]]; then
        log_error "Deployment $deployment not ready: $ready_replicas/$desired_replicas replicas"
        return 1
    fi

    # Check pod status
    local unhealthy_pods=$(kubectl get pods -n "$NAMESPACE" -l "app=$APP_NAME,color=$color" --no-headers | grep -v "Running\|Completed" | wc -l)

    if [[ "$unhealthy_pods" -gt 0 ]]; then
        log_error "Found $unhealthy_pods unhealthy pods in $color environment"
        kubectl get pods -n "$NAMESPACE" -l "app=$APP_NAME,color=$color"
        return 1
    fi

    log_success "Kubernetes resources validation passed for $color environment"
    return 0
}

# Validate database connectivity (if applicable)
validate_database() {
    local color=$1

    log_info "Validating database connectivity for $color environment"

    # This is a placeholder for database validation
    # You would implement actual database checks here
    # For example, checking if the app can connect to a database

    log_info "Database validation skipped (implement based on your database setup)"
    return 0
}

# Comprehensive validation
comprehensive_validation() {
    local color=$1
    local base_url=$2

    log_info "Starting comprehensive validation for $color environment"

    local validation_passed=true

    # Validate Kubernetes resources
    if ! validate_k8s_resources "$color"; then
        validation_passed=false
    fi

    # Validate HTTP endpoints
    if [[ -n "$base_url" ]]; then
        if ! validate_app_health "$color" "$base_url"; then
            validation_passed=false
        fi
    fi

    # Validate database connectivity
    if ! validate_database "$color"; then
        validation_passed=false
    fi

    if [[ "$validation_passed" == true ]]; then
        log_success "Comprehensive validation PASSED for $color environment"
        return 0
    else
        log_error "Comprehensive validation FAILED for $color environment"
        return 1
    fi
}

# Performance validation
validate_performance() {
    local color=$1
    local base_url=$2
    local concurrency="${3:-10}"
    local requests="${4:-100}"

    log_info "Running performance validation for $color environment"

    # Use Apache Bench or similar tool for load testing
    if command -v ab &> /dev/null; then
        log_info "Running load test: $concurrency concurrent requests, $requests total"

        local result=$(ab -n "$requests" -c "$concurrency" -g /dev/null "$base_url/" 2>/dev/null)

        # Extract metrics
        local requests_per_sec=$(echo "$result" | grep "Requests per second" | awk '{print $4}')
        local failed_requests=$(echo "$result" | grep "Failed requests" | awk '{print $3}')

        log_info "Performance results: $requests_per_sec req/sec, $failed_requests failed requests"

        # Check if performance meets minimum requirements
        if (( $(echo "$requests_per_sec < 10" | bc -l 2>/dev/null || echo "1") )); then
            log_warning "Low requests per second: $requests_per_sec (threshold: 10)"
        fi

        if [[ "$failed_requests" -gt 0 ]]; then
            log_warning "Failed requests detected: $failed_requests"
        fi

        log_success "Performance validation completed"
    else
        log_warning "Apache Bench (ab) not found, skipping performance validation"
    fi
}

# Main validation function
main() {
    local color="${1:-}"
    local base_url="${2:-}"
    local check_type="${3:-comprehensive}"

    if [[ -z "$color" ]]; then
        log_error "Color (blue/green) is required"
        echo "Usage: $0 COLOR [BASE_URL] [CHECK_TYPE]"
        echo "  COLOR: blue or green"
        echo "  BASE_URL: Base URL for HTTP validation (optional)"
        echo "  CHECK_TYPE: comprehensive, k8s, http, performance (default: comprehensive)"
        exit 1
    fi

    case "$check_type" in
        comprehensive)
            comprehensive_validation "$color" "$base_url"
            ;;
        k8s)
            validate_k8s_resources "$color"
            ;;
        http)
            if [[ -z "$base_url" ]]; then
                log_error "BASE_URL is required for HTTP validation"
                exit 1
            fi
            validate_app_health "$color" "$base_url"
            ;;
        performance)
            if [[ -z "$base_url" ]]; then
                log_error "BASE_URL is required for performance validation"
                exit 1
            fi
            validate_performance "$color" "$base_url"
            ;;
        *)
            log_error "Unknown check type: $check_type"
            exit 1
            ;;
    esac
}

# Parse command line arguments
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
        --retries)
            RETRIES="$2"
            shift 2
            ;;
        blue|green)
            COLOR="$1"
            shift
            ;;
        *)
            if [[ -z "$BASE_URL" ]]; then
                BASE_URL="$1"
            elif [[ -z "$CHECK_TYPE" ]]; then
                CHECK_TYPE="$1"
            fi
            shift
            ;;
    esac
done

# Set defaults
COLOR="${COLOR:-$1}"
BASE_URL="${BASE_URL:-$2}"
CHECK_TYPE="${CHECK_TYPE:-${3:-comprehensive}}"

# Run validation
main "$COLOR" "$BASE_URL" "$CHECK_TYPE"