from pydantic import BaseModel, Field, ConfigDict
from typing import Optional, Literal

# Definiujemy dozwolone języki w jednym miejscu aplikacji (np. Angielski, Polski, Hiszpański, Niemiecki)
SupportedLanguages = Literal[
    "aa", "ab", "af", "ak", "am", "an", "ar", "as", "av", "ay", 
    "az", "ba", "be", "bg", "bi", "bm", "bn", "bo", "br", "bs", 
    "ca", "ce", "ch", "co", "cr", "cs", "cv", "cy", "da", "de", 
    "dv", "dz", "ee", "el", "en", "es", "et", "eu", "fa", "ff", 
    "fi", "fj", "fo", "fr", "fy", "ga", "gd", "gl", "gn", "gu", 
    "gv", "ha", "he", "hi", "ho", "hr", "ht", "hu", "hy", 
    "hz", "id", "ig", "ii", "ik", "is", "it", "iu", "ja", "jv", 
    "ka", "kg", "ki", "kj", "kk", "kl", "km", "kn", "ko", "kr", 
    "ks", "ku", "kv", "kw", "ky", "lb", "lg", "li", "ln", "lo", 
    "lt", "lu", "lv", "mg", "mh", "mi", "mk", "ml", "mn", "mr", 
    "ms", "mt", "my", "na", "nb", "nd", "ne", "ng", "nl", "nn", 
    "no", "nr", "nv", "ny", "oc", "oj", "om", "or", "os", "pa", 
    "pl", "ps", "pt", "qu", "rm", "rn", "ro", "ru", "rw", "sc", 
    "sd", "se", "sg", "si", "sk", "sl", "sm", "sn", "so", "sq", 
    "sr", "ss", "st", "su", "sv", "sw", "ta", "te", "tg", "th", 
    "ti", "tk", "tl", "tn", "to", "tr", "ts", "tt", "tw", "ty", 
    "ug", "uk", "ur", "uz", "ve", "vi", "wa", "wo", "xh", "yi", 
    "yo", "za", "zh", "zu"
]

class UserProfileBase(BaseModel):
    # Pydantic sam sprawdzi czy wysłano jedną z dozwolonych wartości z SupportedLanguages
    native_language: SupportedLanguages = Field(
        default="en", 
        description="Supported ISO 639-1 language codes"
    )
    ui_theme: Literal["light", "dark", "system"] = Field(
        default="system", 
        description="UI theme preference"
    )
    # ================= [ZMIANA 1]: Dodanie pola wyjściowego =================
    is_onboarding_completed: bool = Field(
        default=False,
        description="Flag indicating whether the user has completed the initial account setup."
    )
    # ========================================================================

class UserProfileUpdate(BaseModel):
    native_language: Optional[SupportedLanguages] = Field(None)
    ui_theme: Optional[Literal["light", "dark", "system"]] = Field(None)
    # ================= [ZMIANA 2]: Umożliwiamy nadpisanie flagi z frontendu =================
    is_onboarding_completed: Optional[bool] = Field(None)
    # ========================================================================================

class UserProfilePublic(UserProfileBase):
    model_config = ConfigDict(from_attributes=True)