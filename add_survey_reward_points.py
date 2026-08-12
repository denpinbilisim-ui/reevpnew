#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Migration script to add reward_points column to Survey table
"""

from app import app, db, Survey
import sqlite3

def add_reward_points_column():
    with app.app_context():
        try:
            # SQLite için manuel migration
            db_path = 'instance/cafe_loyalty.db'
            conn = sqlite3.connect(db_path)
            cursor = conn.cursor()
            
            # Sütun var mı kontrol et
            cursor.execute("PRAGMA table_info(survey)")
            columns = [column[1] for column in cursor.fetchall()]
            
            if 'reward_points' not in columns:
                print("Adding reward_points column to survey table...")
                cursor.execute("ALTER TABLE survey ADD COLUMN reward_points INTEGER DEFAULT 0")
                conn.commit()
                print("reward_points column added successfully!")
            else:
                print("reward_points column already exists")
            
            conn.close()
            
            # Flask-SQLAlchemy ile tabloları güncelle
            db.create_all()
            print("Database tables updated")
            
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    add_reward_points_column()
