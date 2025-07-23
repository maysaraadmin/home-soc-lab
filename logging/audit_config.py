"""
Audit Logging Configuration for SOC Environment

This module provides a centralized audit logging configuration that can be used
across all SOC components to ensure consistent audit logging format and behavior.
"""
import os
import json
import logging
import logging.handlers
from datetime import datetime
from typing import Dict, Any, Optional, List, Union

# Default audit log fields
DEFAULT_AUDIT_FIELDS = [
    'timestamp',
    'event_type',
    'user',
    'source_ip',
    'action',
    'resource',
    'status',
    'details'
]

class AuditLogger:
    """
    A class for handling audit logging in a standardized format.
    """
    
    def __init__(
        self,
        name: str = 'soc.audit',
        log_file: Optional[str] = None,
        max_bytes: int = 10 * 1024 * 1024,  # 10 MB
        backup_count: int = 10,
        syslog: bool = False
    ):
        """
        Initialize the audit logger.
        
        Args:
            name: Logger name
            log_file: Path to the audit log file
            max_bytes: Maximum log file size before rotation
            backup_count: Number of backup log files to keep
            syslog: Whether to enable syslog logging
        """
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.INFO)
        
        # Clear any existing handlers
        self.logger.handlers.clear()
        
        # Create formatter with JSON format
        self.formatter = logging.Formatter('%(message)s')
        
        # File handler for audit logs
        if log_file:
            self._setup_file_handler(log_file, max_bytes, backup_count)
        
        # Syslog handler (if enabled)
        if syslog:
            self._setup_syslog_handler()
        
        # Don't propagate to root logger
        self.logger.propagate = False
    
    def _setup_file_handler(
        self,
        log_file: str,
        max_bytes: int,
        backup_count: int
    ) -> None:
        """Set up file handler for audit logs."""
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(os.path.abspath(log_file)), exist_ok=True)
        
        file_handler = logging.handlers.RotatingFileHandler(
            log_file,
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setFormatter(self.formatter)
        self.logger.addHandler(file_handler)
    
    def _setup_syslog_handler(self) -> None:
        """Set up syslog handler for audit logs."""
        try:
            syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
            syslog_handler.setFormatter(self.formatter)
            self.logger.addHandler(syslog_handler)
        except Exception as e:
            logging.warning(f"Failed to configure syslog: {e}")
    
    def log(
        self,
        event_type: str,
        user: str,
        source_ip: str,
        action: str,
        resource: str,
        status: str,
        details: Optional[Dict[str, Any]] = None,
        **kwargs
    ) -> None:
        """
        Log an audit event.
        
        Args:
            event_type: Type of event (e.g., 'authentication', 'authorization', 'data_access')
            user: Username or service account performing the action
            source_ip: Source IP address of the request
            action: Action performed (e.g., 'login', 'read', 'update', 'delete')
            resource: Resource being accessed or modified
            status: Status of the action (e.g., 'success', 'failure', 'denied')
            details: Additional details about the event
            **kwargs: Additional fields to include in the audit log
        """
        # Create audit record
        audit_record = {
            'timestamp': datetime.utcnow().isoformat() + 'Z',
            'event_type': event_type,
            'user': user,
            'source_ip': source_ip,
            'action': action,
            'resource': resource,
            'status': status,
            'details': details or {}
        }
        
        # Add any additional fields
        audit_record.update(kwargs)
        
        # Log the audit record as JSON
        self.logger.info(json.dumps(audit_record, default=str))


# Default audit logger instance
def get_audit_logger() -> AuditLogger:
    """
    Get the default audit logger instance.
    
    Returns:
        Configured AuditLogger instance
    """
    log_dir = os.getenv('LOG_DIR', '/var/log/soc')
    audit_log = os.path.join(log_dir, 'audit.log')
    
    if not hasattr(get_audit_logger, '_instance'):
        get_audit_logger._instance = AuditLogger(
            log_file=audit_log,
            max_bytes=10 * 1024 * 1024,  # 10 MB
            backup_count=10
        )
    
    return get_audit_logger._instance


# Example usage
if __name__ == "__main__":
    # Get the default audit logger
    audit_logger = get_audit_logger()
    
    # Example audit events
    audit_logger.log(
        event_type='authentication',
        user='admin@example.com',
        source_ip='192.168.1.100',
        action='login',
        resource='/api/v1/auth/login',
        status='success',
        details={
            'auth_method': 'password',
            'mfa_used': True
        }
    )
    
    audit_logger.log(
        event_type='data_access',
        user='analyst@example.com',
        source_ip='10.0.0.15',
        action='read',
        resource='/api/v1/incidents/123',
        status='success',
        details={
            'incident_id': '123',
            'sensitivity': 'high'
        }
    )
