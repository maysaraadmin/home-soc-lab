// Services Management JavaScript

document.addEventListener('DOMContentLoaded', function() {
    // Initialize tooltips
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Handle service start/stop buttons
    document.addEventListener('click', function(e) {
        // Handle start button click
        if (e.target.closest('.service-start')) {
            const button = e.target.closest('.service-start');
            const serviceName = button.dataset.service;
            controlService(serviceName, 'start');
        }
        
        // Handle stop button click
        if (e.target.closest('.service-stop')) {
            const button = e.target.closest('.service-stop');
            const serviceName = button.dataset.service;
            controlService(serviceName, 'stop');
        }
    });

    // Initial load of services status
    updateServicesStatus();
    
    // Set up auto-refresh of services status every 10 seconds
    setInterval(updateServicesStatus, 10000);
});

// Control a service (start/stop/restart)
async function controlService(serviceName, action) {
    try {
        // Disable the button and show loading state
        const button = document.querySelector(`.service-${action}[data-service="${serviceName}"]`);
        const originalText = button.innerHTML;
        button.disabled = true;
        button.innerHTML = '<i class="fas fa-spinner fa-spin me-1"></i> ' + 
                          (action === 'start' ? 'Starting' : 'Stopping') + '...';

        // Call the API to control the service
        const response = await fetch(`/api/services/control/${serviceName}/${action}`, {
            method: 'POST'
        });
        
        const result = await response.json();
        
        if (result.success) {
            showNotification(result.message, 'success');
            // Refresh the services status
            updateServicesStatus();
        } else {
            showNotification(result.message || `Failed to ${action} service`, 'error');
            // Reset button state
            button.disabled = false;
            button.innerHTML = originalText;
        }
    } catch (error) {
        console.error('Error controlling service:', error);
        showNotification(`Error: ${error.message}`, 'error');
        
        // Reset button state
        const button = document.querySelector(`.service-${action}[data-service="${serviceName}"]`);
        if (button) {
            button.disabled = false;
            button.innerHTML = originalText;
        }
    }
}

// Update the status of all services
async function updateServicesStatus() {
    try {
        // Show loading state
        const serviceCards = document.querySelectorAll('.service-card');
        serviceCards.forEach(card => {
            const statusBadge = card.querySelector('.badge');
            if (statusBadge) {
                statusBadge.innerHTML = '<i class="fas fa-circle-notch fa-spin me-1"></i> Updating...';
                statusBadge.className = 'badge bg-secondary';
            }
        });

        // Get the current container status
        const response = await fetch('/api/containers/status');
        const data = await response.json();
        const containerStatuses = data.containers || {};

        // Update each service card
        serviceCards.forEach(card => {
            const serviceName = card.dataset.service.toLowerCase();
            const statusBadge = card.querySelector('.badge');
            const startButton = card.querySelector('.service-start');
            const stopButton = card.querySelector('.service-stop');
            const openButton = card.querySelector('a[target="_blank"]');
            
            // Find the container status for this service
            let status = 'stopped';
            let containerId = null;
            
            for (const [containerName, containerInfo] of Object.entries(containerStatuses)) {
                if (containerName.toLowerCase().includes(serviceName)) {
                    status = containerInfo.status.toLowerCase();
                    containerId = containerInfo.id;
                    break;
                }
            }
            
            // Update the UI based on the status
            if (statusBadge) {
                if (status === 'running') {
                    statusBadge.className = 'badge bg-success';
                    statusBadge.innerHTML = '<i class="fas fa-check-circle me-1"></i> Running';
                    
                    if (startButton) startButton.disabled = true;
                    if (stopButton) stopButton.disabled = false;
                    if (openButton) openButton.disabled = false;
                } else {
                    statusBadge.className = 'badge bg-secondary';
                    statusBadge.innerHTML = '<i class="fas fa-stop-circle me-1"></i> Stopped';
                    
                    if (startButton) startButton.disabled = false;
                    if (stopButton) stopButton.disabled = true;
                    if (openButton) openButton.disabled = true;
                }
            }
            
            // Update the service icon color based on status
            const icon = card.querySelector('.fa-2x');
            if (icon) {
                if (status === 'running') {
                    icon.style.color = 'var(--accent-green)';
                } else {
                    icon.style.color = 'var(--accent-red)';
                }
            }
        });
        
    } catch (error) {
        console.error('Error updating services status:', error);
        showNotification('Error updating services status', 'error');
    }
}

// Show a notification to the user
function showNotification(message, type = 'info') {
    const notification = document.createElement('div');
    notification.className = `alert alert-${type} alert-dismissible fade show`;
    notification.role = 'alert';
    notification.innerHTML = `
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
    
    const notificationContainer = document.getElementById('notificationContainer');
    if (notificationContainer) {
        notificationContainer.appendChild(notification);
        
        // Auto-remove the notification after 5 seconds
        setTimeout(() => {
            notification.remove();
        }, 5000);
    }
}
