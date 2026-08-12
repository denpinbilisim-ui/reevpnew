# PWA İkonları

PWA için aşağıdaki boyutlarda ikonlar gereklidir:

## Gerekli İkon Boyutları:
- icon-72x72.png
- icon-96x96.png
- icon-128x128.png
- icon-144x144.png
- icon-152x152.png
- icon-192x192.png ✓ (mevcut)
- icon-384x384.png
- icon-512x512.png ✓ (mevcut)

## İkon Oluşturma:

### Yöntem 1: Online Araçlar
1. https://www.pwabuilder.com/imageGenerator adresine gidin
2. Logo dosyanızı yükleyin
3. Tüm boyutları indirin
4. Bu klasöre kopyalayın

### Yöntem 2: ImageMagick (Komut Satırı)
```bash
# Mevcut 512x512 ikondan diğer boyutları oluştur
magick icon-512.png -resize 72x72 icon-72x72.png
magick icon-512.png -resize 96x96 icon-96x96.png
magick icon-512.png -resize 128x128 icon-128x128.png
magick icon-512.png -resize 144x144 icon-144x144.png
magick icon-512.png -resize 152x152 icon-152x152.png
magick icon-512.png -resize 192x192 icon-192x192.png
magick icon-512.png -resize 384x384 icon-384x384.png
```

### Yöntem 3: Python ile Otomatik
```python
from PIL import Image
import os

sizes = [72, 96, 128, 144, 152, 192, 384, 512]
base_image = Image.open('icon-512.png')

for size in sizes:
    resized = base_image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(f'icon-{size}x{size}.png')
```

## Geçici Çözüm:
Şu an için mevcut icon-192.png ve icon-512.png dosyaları kullanılabilir.
Eksik boyutlar için tarayıcı otomatik olarak en yakın boyutu kullanacaktır.
