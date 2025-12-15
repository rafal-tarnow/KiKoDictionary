from PIL import Image, ImageDraw, ImageFont
import random
import string
import io
import base64
from typing import Tuple

class CaptchaGenerator:
    def __init__(self, width: int, height: int, length: int):
        self.width = width
        self.height = height
        self.length = length
        self.characters = string.ascii_uppercase + string.digits
        self.font_size = int(height * 0.5)

    def generate_captcha(self) -> Tuple[str, str]:
        # Generate random text
        text = ''.join(random.choice(self.characters) for _ in range(self.length))
        
        print(f"CAPTCHA TEXT = {text}")

        # Create image
        image = Image.new('RGB', (self.width, self.height), color='white')
        draw = ImageDraw.Draw(image)
        
        # Try to load a font, fallback to default if not available
        try:
            #font = ImageFont.truetype("../../assets/fonts/Domestic_Manners.ttf", self.font_size)
            font = ImageFont.truetype("../../assets/fonts/Arial.ttf", self.font_size)
        except:
            font = ImageFont.load_default()

        # Add text to image
        text_width = draw.textlength(text, font=font)
        text_position = ((self.width - text_width) / 2, (self.height - self.font_size) / 2)
        draw.text(text_position, text, fill='black', font=font)

        # Add noise
        for _ in range(100):
            x = random.randint(0, self.width)
            y = random.randint(0, self.height)
            draw.point((x, y), fill='gray')

        # Convert to base64
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode()

        return text, f"data:image/png;base64,{img_str}"