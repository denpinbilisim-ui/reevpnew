#!/usr/bin/env python3
"""
User tablosuna auth_token alanı eklemek için migration script
"""

import sqlite3
import os

def add_auth_token_column():
    # Database dosyasının yolu
    db_path = 'cafe_loyalty.db'
    
    if not os.path.exists(db_path):
        print(f"Database dosyası bulunamadı: {db_path}")
        return False
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Önce sütun var mı kontrol et
        cursor.execute("PRAGMA table_info(user)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'auth_token' not in columns:
            # Auth token sütunu ekle
            cursor.execute('ALTER TABLE user ADD COLUMN auth_token TEXT')
            print("✅ Auth token sütunu eklendi!")
        else:
            print("ℹ️ Auth token sütunu zaten mevcut")
        
        # Index ekle (performans için)
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_user_auth_token ON user(auth_token)')
        print("✅ Auth token index'i eklendi!")
        
        conn.commit()
        conn.close()
        
        print("🎉 Migration başarıyla tamamlandı!")
        return True
        
    except Exception as e:
        print(f"❌ Hata oluştu: {e}")
        return False

if __name__ == "__main__":
    print("User tablosuna auth_token sütunu ekleniyor...")
    add_auth_token_column()
