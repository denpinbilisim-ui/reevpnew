#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Migration script to add UserSurveyView table for survey notifications
"""

from app import app, db, UserSurveyView
import sqlite3

def add_survey_notifications_table():
    with app.app_context():
        try:
            # Flask-SQLAlchemy ile tabloları oluştur
            db.create_all()
            print("✓ UserSurveyView table created successfully!")
            
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    add_survey_notifications_table()
