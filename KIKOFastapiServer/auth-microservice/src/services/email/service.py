import os
from pathlib import Path
from typing import List

from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from src.core.config import settings

# Ustalanie ścieżki do szablonów w sposób niezależny od systemu operacyjnego
# __file__ to ścieżka do tego pliku (service.py).
# .parent to katalog 'email', a / 'templates' to podkatalog.
TEMPLATE_FOLDER = Path(__file__).resolve().parent / "templates"

class EmailService:
    def __init__(self):
        # Konfiguracja połączenia SMTP
        self.conf = ConnectionConfig(
            MAIL_USERNAME=settings.SMTP_USER,
            MAIL_PASSWORD=settings.SMTP_PASSWORD,
            MAIL_FROM=settings.EMAILS_FROM_EMAIL,
            MAIL_PORT=settings.SMTP_PORT,
            MAIL_SERVER=settings.SMTP_HOST,
            MAIL_FROM_NAME=settings.EMAILS_FROM_NAME,
            MAIL_STARTTLS=True,  # Zazwyczaj True dla portu 587
            MAIL_SSL_TLS=False,  # Zazwyczaj False dla portu 587 (True dla 465)
            USE_CREDENTIALS=True,
            VALIDATE_CERTS=True,
            TEMPLATE_FOLDER=TEMPLATE_FOLDER
        )
        self.fast_mail = FastMail(self.conf)

    async def send_reset_password_email(self, email_to: str, token: str):
        """
        Wysyła prawdziwy email z użyciem szablonu HTML.
        """
        # 1. Przygotowanie danych do szablonu (Context)
        reset_link = f"{settings.FRONTEND_URL}/auth/reset-password?token={token}"
        
        template_body = {
            "app_name": settings.EMAILS_FROM_NAME,
            "link": reset_link,
            "valid_minutes": settings.RESET_TOKEN_EXPIRE_MINUTES,
            "subject": "Reset Your Password" # Przekazujemy też do base.html
        }

        # 2. Tworzenie wiadomości
        message = MessageSchema(
            subject="Reset Your Password - Action Required",
            recipients=[email_to], # Lista odbiorców
            template_body=template_body,
            subtype=MessageType.html # Ważne: wysyłamy HTML
        )

        # 3. Wysyłka
        try:
            # template_name musi pasować do nazwy pliku w katalogu templates
            await self.fast_mail.send_message(message, template_name="reset_password.html")
            print(f"LOG: Email sent to {email_to}")
        except Exception as e:
            print(f"ERROR: Failed to send email to {email_to}. Error: {e}")
            # W produkcji tutaj dodałbyś logowanie do pliku lub Sentry
            # Nie rzucamy wyjątku, żeby nie przerywać działania aplikacji (to leci w tle)

email_service = EmailService()