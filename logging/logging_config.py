"""
Logging configuration for the SOC environment.

This module provides a centralized logging configuration that can be used across
all SOC components to ensure consistent logging format and behavior.
"""
import os
import logging
import logging.handlers
from typing import Dict, Any, Optional

# Log format string
LOG_FORMAT = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
DATE_FORMAT = "%Y-%m-%d %H:%M:%S %z"

# Log levels as strings to actual logging levels
LOG_LEVELS = {
    'DEBUG': logging.DEBUG,
    'INFO': logging.INFO,
    'WARNING': logging.WARNING,
    'ERROR': logging.ERROR,
    'CRITICAL': logging.CRITICAL
}

def setup_logger(
    name: str = 'soc',
    log_level: str = 'INFO',
    log_file: Optional[str] = None,
    max_bytes: int = 10 * 1024 * 1024,  # 10 MB
    backup_count: int = 5,
    syslog: bool = False
) -> logging.Logger:
    """
    Configure and return a logger with the specified settings.
    
    Args:
        name: Logger name
        log_level: Logging level as string (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        log_file: Path to log file (if file logging is desired)
        max_bytes: Maximum log file size before rotation
        backup_count: Number of backup log files to keep
        syslog: Whether to enable syslog logging
        
    Returns:
        Configured logger instance
    """
    # Get the logger
    logger = logging.getLogger(name)
    
    # Clear any existing handlers to avoid duplicate logs
    logger.handlers.clear()
    
    # Set the log level
    level = LOG_LEVELS.get(log_level.upper(), logging.INFO)
    logger.setLevel(level)
    
    # Create formatter
    formatter = logging.Formatter(LOG_FORMAT, DATE_FORMAT)
    
    # Console handler (always enabled)
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)
    
    # File handler (if log file is specified)
    if log_file:
        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(os.path.abspath(log_file)), exist_ok=True)
        
        file_handler = logging.handlers.RotatingFileHandler(
            log_file,
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    
    # Syslog handler (if enabled)
    if syslog:
        try:
            syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
            syslog_handler.setFormatter(formatter)
            logger.addHandler(syslog_handler)
        except Exception as e:
            logger.warning(f"Failed to configure syslog: {e}")
    
    return logger

def get_audit_logger() -> logging.Logger:
    """
    Get a pre-configured audit logger.
    
    Returns:
        Logger instance configured for audit logging
    """
    logger = logging.getLogger('soc.audit')
    if not logger.handlers:
        # Configure audit logging to a separate file
        log_dir = os.getenv('LOG_DIR', '/var/log/soc')
        audit_log = os.path.join(log_dir, 'audit.log')
        
        # Ensure log directory exists
        os.makedirs(log_dir, exist_ok=True)
        
        # Set up the audit logger
        logger.setLevel(logging.INFO)
        
        # File handler for audit logs
        file_handler = logging.handlers.RotatingFileHandler(
            audit_log,
            maxBytes=10 * 1024 * 1024,  # 10 MB
            backupCount=10,
            encoding='utf-8'
        )
        
        # Custom format for audit logs
        audit_formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            '%Y-%m-%d %H:%M:%S %z'
        )
        file_handler.setFormatter(audit_formatter)
        
        # Add handler
        logger.addHandler(file_handler)
        
        # Don't propagate to root logger
        logger.propagate = False
    
    return logger

# Example usage
if __name__ == "__main__":
    # Basic setup
    logger = setup_logger('example', 'DEBUG', 'example.log')
    logger.info("This is an info message")
    logger.error("This is an error message")
    
    # Audit logging
    audit_logger = get_audit_logger()
    audit_logger.info("User 'admin' logged in from 192.168.1.100")
