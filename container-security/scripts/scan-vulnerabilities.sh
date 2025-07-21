#!/bin/bash
# Container vulnerability scanning script

set -euo pipefail

# Configuration
SCAN_DIR="/scans"
LOG_FILE="/var/log/container-scans/scan-$(date +%Y%m%d).log"
REPORT_DIR="/reports/$(date +%Y%m%d_%H%M%S)"
TRIVY_CACHE_DIR="/root/.cache/trivy"
SEVERITY_THRESHOLD="HIGH,CRITICAL"

# Create necessary directories
mkdir -p "${REPORT_DIR}" "${SCAN_DIR}" "$(dirname "${LOG_FILE}")" "${TRIVY_CACHE_DIR}"

# Log function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    error_exit "Trivy is not installed. Please install it first."
fi

# Function to scan a single container
scan_container() {
    local container_id="$1"
    local image_name
    image_name=$(docker inspect --format='{{.Config.Image}}' "$container_id")
    local safe_name
    safe_name=$(echo "$image_name" | tr "/:" "_")
    
    log "Scanning container $container_id (Image: $image_name)"
    
    # Run Trivy scan
    if ! trivy container --severity "$SEVERITY_THRESHOLD" -f json -o "${REPORT_DIR}/container-${container_id}.json" "$container_id"; then
        log "Error scanning container $container_id"
        return 1
    fi
    
    # Generate HTML report
    if [ -s "${REPORT_DIR}/container-${container_id}.json" ]; then
        trivy convert --format template --template "@/contrib/html.tpl" -o "${REPORT_DIR}/container-${safe_name}.html" "${REPORT_DIR}/container-${container_id}.json"
        log "Report generated: ${REPORT_DIR}/container-${safe_name}.html"
        return 0
    else
        rm -f "${REPORT_DIR}/container-${container_id}.json"
        log "No vulnerabilities found in container $container_id"
        return 0
    fi
}

# Function to scan all running containers
scan_running_containers() {
    log "Scanning all running containers..."
    local vuln_found=false
    
    # Get list of running container IDs
    local containers
    containers=$(docker ps -q)
    
    if [ -z "$containers" ]; then
        log "No running containers found."
        return 0
    fi
    
    for container in $containers; do
        if ! scan_container "$container"; then
            vuln_found=true
        fi
    done
    
    if [ "$vuln_found" = true ]; then
        log "Vulnerabilities found in one or more containers. Check the reports in ${REPORT_DIR}"
        return 1
    else
        log "No vulnerabilities found in running containers."
        return 0
    fi
}

# Main execution
case "${1:-}" in
    container)
        if [ -z "${2:-}" ]; then
            error_exit "Container ID not specified"
        fi
        scan_container "$2"
        ;;
    *)
        scan_running_containers
        ;;
esac

exit 0
