from PIL import Image
import os
import sys

# UTF-8 encoding için
sys.stdout.reconfigure(encoding='utf-8')

# Kaynak ikon
source_icon = r'C:\Users\Denpin\Downloads\reevpoints.tr-20251226T131301Z-1-001\reevpoints.tr\static\icons\app_icon.png'
output_dir = r'C:\Users\Denpin\Downloads\reevpoints.tr-20251226T131301Z-1-001\reevpoints.tr\static\icons'

# PWA için gerekli boyutlar
sizes = [72, 96, 128, 144, 152, 192, 384, 512]

try:
    # Kaynak ikonu aç
    img = Image.open(source_icon)
    print(f"[OK] Kaynak ikon yuklendi: {img.size}")
    
    # Her boyut için ikon oluştur
    for size in sizes:
        # Yeniden boyutlandır
        resized = img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Kaydet
        output_path = os.path.join(output_dir, f'icon-{size}x{size}.png')
        resized.save(output_path, 'PNG', optimize=True)
        print(f"[OK] Olusturuldu: icon-{size}x{size}.png")
    
    print("\n[SUCCESS] Tum PWA ikonlari basariyla olusturuldu!")
    
except Exception as e:
    print(f"[ERROR] Hata: {e}")
