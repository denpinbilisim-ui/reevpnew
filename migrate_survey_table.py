#!/usr/bin/env python3
"""
Database migration script to add reward_points column to survey table
"""

import sqlite3
import os
from datetime import datetime

def migrate_survey_table():
    """Add reward_points column to survey table if it doesn't exist"""
    
    # Database file path
    db_path = os.path.join(os.path.dirname(__file__), 'cafe_loyalty.db')
    
    if not os.path.exists(db_path):
        print(f"Database file not found: {db_path}")
        return False
    
    try:
        # Connect to database
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check if reward_points column exists
        cursor.execute("PRAGMA table_info(survey)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'reward_points' not in columns:
            print("Adding reward_points column to survey table...")
            
            # Add the reward_points column with default value 0
            cursor.execute("""
                ALTER TABLE survey 
                ADD COLUMN reward_points INTEGER DEFAULT 0
            """)
            
            print("✓ reward_points column added successfully")
            
            # Update existing surveys to have 0 reward points if they don't have a value
            cursor.execute("""
                UPDATE survey 
                SET reward_points = 0 
                WHERE reward_points IS NULL
            """)
            
            conn.commit()
            print("✓ Existing surveys updated with default reward_points = 0")
            
        else:
            print("✓ reward_points column already exists")
        
        # Verify the column was added
        cursor.execute("PRAGMA table_info(survey)")
        columns_after = [column[1] for column in cursor.fetchall()]
        
        if 'reward_points' in columns_after:
            print("✓ Migration completed successfully")
            return True
        else:
            print("✗ Migration failed - column not found after addition")
            return False
            
    except sqlite3.Error as e:
        print(f"✗ Database error: {e}")
        return False
    except Exception as e:
        print(f"✗ Unexpected error: {e}")
        return False
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    print("=" * 50)
    print("Survey Table Migration Script")
    print("=" * 50)
    print(f"Starting migration at {datetime.now()}")
    print()
    
    success = migrate_survey_table()
    
    print()
    if success:
        print("✓ Migration completed successfully!")
        print("You can now create surveys with reward points.")
    else:
        print("✗ Migration failed!")
        print("Please check the error messages above.")
    
    print("=" * 50)
