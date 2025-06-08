#!/usr/bin/env python3

"""
A simple notification system script.
Placeholder for further notification logic.
"""

import smtplib

# Corrected email imports as per the task
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def send_notification(subject, body, sender, recipient, smtp_server):
    """
    Sends an email notification.
    """
    msg = MIMEMultipart()
    msg['From'] = sender
    msg['To'] = recipient
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(smtp_server) as server:
            server.sendmail(sender, recipient, msg.as_string())
        print(f"Notification sent successfully to {recipient}")
    except Exception as e:
        print(f"Error sending notification: {e}")

if __name__ == "__main__":
    # Example usage (replace with actual values or configuration)
    # This is a placeholder and would typically be driven by other script logic
    print("Notification system script initialized.")
    # send_notification(
    #     subject="Test Notification",
    #     body="This is a test notification from the system.",
    #     sender="noreply@example.com",
    #     recipient="admin@example.com",
    #     smtp_server="localhost" # Replace with your SMTP server
    # )

# Example function demonstrating authenticated SMTP sending
def send_authenticated_notification(subject, body, recipient, smtp_server, smtp_port=587):
    """
    Sends an email notification using SMTP authentication (TLS).
    """
    import os # For getenv

    SENDER_EMAIL = os.getenv("SENDER_EMAIL")
    SENDER_PASSWORD = os.getenv("SENDER_PASSWORD")

    if SENDER_EMAIL is None or SENDER_PASSWORD is None:
        print("Error: SENDER_EMAIL or SENDER_PASSWORD environment variables not set.")
        print("Skipping authenticated notification.")
        return

    msg = MIMEMultipart()
    msg['From'] = SENDER_EMAIL
    msg['To'] = recipient
    msg['Subject'] = subject

    msg.attach(MIMEText(body, 'plain'))

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()  # Secure the connection
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.sendmail(SENDER_EMAIL, recipient, msg.as_string())
        print(f"Authenticated notification sent successfully to {recipient}")
    except smtplib.SMTPAuthenticationError as e:
        print(f"SMTP Authentication Error: {e}. Check credentials or server configuration.")
    except Exception as e:
        print(f"Error sending authenticated notification: {e}")

# Example of calling the authenticated notification (can be uncommented for testing)
# if __name__ == "__main__":
#     send_authenticated_notification(
#         subject="Authenticated Test Notification",
#         body="This is a test notification using SMTP authentication.",
#         recipient="test@example.com", # Replace with a real recipient for testing
#         smtp_server="smtp.example.com"  # Replace with your SMTP server
#     )
