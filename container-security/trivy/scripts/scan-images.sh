#!/bin/bash
# Script to scan container images using Trivy

set -euo pipefail

# Create reports directory if it doesn't exist
mkdir -p /reports

# Get list of running container images
IMAGES=$(docker ps --format '{{.Image}}' | sort -u)

# Current timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_DIR="/reports/scan_${TIMESTAMP}"
mkdir -p "${REPORT_DIR}"

# Function to get image name without tag
get_image_name() {
    local image=$1
    echo "${image}" | cut -d':' -f1 | tr '/:' '_'
}

# Scan each image
for image in $IMAGES; do
    echo "Scanning image: $image"
    IMAGE_NAME=$(get_image_name "$image")
    
    # Run Trivy scan
    trivy image --format template --template "@/contrib/html.tpl" -o "${REPORT_DIR}/${IMAGE_NAME}_${TIMESTAMP}.html" "$image" || true
    
    # Also generate JSON report
    trivy image -f json -o "${REPORT_DIR}/${IMAGE_NAME}_${TIMESTAMP}.json" "$image" || true
done

# Generate summary report
HTML_FILES=("${REPORT_DIR}/"*.html)
if [ ${#HTML_FILES[@]} -gt 0 ]; then
    echo "<html><body><h1>Trivy Scan Summary - $(date)</h1><ul>" > "${REPORT_DIR}/summary.html"
    for file in "${HTML_FILES[@]}"; do
        filename=$(basename "$file")
        echo "<li><a href=\"${filename}\">${filename}</a></li>" >> "${REPORT_DIR}/summary.html"
    done
    echo "</ul></body></html>" >> "${REPORT_DIR}/summary.html"
fi

echo "Scan completed. Reports saved to ${REPORT_DIR}"
