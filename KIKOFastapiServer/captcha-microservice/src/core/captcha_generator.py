import random
import string
import base64
from typing import Tuple
from captcha.image import ImageCaptcha  # To musisz mieć zainstalowane

class CaptchaGenerator:
    def __init__(self, width: int, height: int, length: int, use_digits: bool = False):
        self.width = width
        self.height = height
        self.length = length

        # PRO TIP: Używamy "Safe Alphabet" (Bez mylących liter: O, I, Q)
        safe_letters = "ABCDEFGHJKLMNPRSTUVWXYZ"
        # Jeśli kiedykolwiek włączysz cyfry, one też są bezpieczne (bez 0 i 1)
        safe_digits = "23456789"
        
        # Budowanie dostępnej puli znaków na podstawie flagi
        if use_digits:
            self.characters = safe_letters + safe_digits
        else:
            self.characters = safe_letters


        # Inicjalizacja generatora z biblioteki.
        # Nie podajemy argumentu 'fonts', więc biblioteka użyje swoich WBUDOWANYCH czcionek.
        # To gwarantuje identyczny wygląd na każdym systemie (Dev/Prod).
        self.image_generator = ImageCaptcha(width=self.width, height=self.height)

    def generate_captcha(self) -> Tuple[str, str]:
        # Generowanie losowego tekstu
        text = ''.join(random.choice(self.characters) for _ in range(self.length))
        
        #print(f"CAPTCHA TEXT = {text}")

        # Generowanie obrazka przez bibliotekę
        # Metoda generate zwraca obiekt BytesIO (strumień bajtów)
        data = self.image_generator.generate(text)
        
        # Konwersja strumienia bajtów na base64 (tak jak w Twoim oryginale)
        # getvalue() pobiera surowe bajty PNG
        img_str = base64.b64encode(data.getvalue()).decode()

        # Zwracamy w formacie zgodnym z Twoim frontendem/API
        return text, f"data:image/png;base64,{img_str}"