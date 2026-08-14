import pandas as pd
import math
import sys
import uuid
from supabase import create_client, Client

url = "https://btzhzudlkrtiatdkbwpe.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ0emh6dWRsa3J0aWF0ZGtid3BlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODQxNzIsImV4cCI6MjA5Nzg2MDE3Mn0.eiRW8kVJFSocLiei3dqpVZhhZyxpEJLwT12rWHJa5NM"
supabase: Client = create_client(url, key)

def get_db_users():
    res = supabase.table('users').select('*').execute()
    db_users = res.data
    # Map by full name
    return {}, {u['full_name'].lower(): u for u in db_users}

def create_user_if_missing(name, staff_code, dept, position):
    # Auto-generate a dummy email
    email_prefix = "".join(c for c in name if ord(c) < 128).strip().lower().replace(" ", ".")
    if not email_prefix:
        email_prefix = f"user_{staff_code.lower()}"
    email = f"{email_prefix}@foodangel.hk"
    
    new_user = {
        "full_name": name,
        "email": email,
        "role": "STAFF",
        "staff_type": "FULL_TIME"
    }
    supabase.table('users').insert(new_user).execute()
    return new_user

def process_file(filename):
    print(f"Processing {filename}...")
    df = pd.read_excel(filename, header=None)
    
    emp_map, name_map = get_db_users()
    
    current_date = None
    records = []
    
    for idx, row in df.iterrows():
        row_list = list(row.values)
        row_strs = [str(x).strip() if pd.notna(x) else "" for x in row_list]
        
        # Check for date
        if "Date:" in row_strs:
            date_idx = row_strs.index("Date:") + 1
            while date_idx < len(row_strs) and not row_strs[date_idx]:
                date_idx += 1
            if date_idx < len(row_strs):
                current_date = row_strs[date_idx]
                
        # Look for valid user row
        name = row_strs[0]
        if name and name not in ["User Name", "Daily In Out Report", ""] and "Date:" not in row_strs:
            staff_code = row_strs[4] if len(row_strs) > 4 else ""
            dept = row_strs[6] if len(row_strs) > 6 else ""
            position = row_strs[8] if len(row_strs) > 8 else ""
            
            in_time = row_strs[13] if len(row_strs) > 13 else ""
            out_time = row_strs[14] if len(row_strs) > 14 else ""
            
            if not in_time or in_time == "-":
                continue # No check-in
                
            out_time = out_time if out_time and out_time != "-" else None
            
            if not staff_code:
                staff_code = f"TEMP-{len(records)}"
                
            # Match user by name
            matched_user = name_map.get(name.lower())
            if not matched_user:
                # create them
                print(f"Creating missing user: {name} ({staff_code})")
                try:
                    matched_user = create_user_if_missing(name, staff_code, dept, position)
                    name_map[name.lower()] = matched_user
                except Exception as e:
                    print(f"Failed to create user {name}: {e}")
                    continue
                    
            # Calc hours
            hours_worked = 0
            overtime_mins = 0
            if out_time:
                try:
                    in_h, in_m = map(int, in_time.split(':'))
                    out_h, out_m = map(int, out_time.split(':'))
                    
                    # Handle crossing midnight or just basic math
                    in_total = in_h * 60 + in_m
                    out_total = out_h * 60 + out_m
                    if out_total < in_total:
                        out_total += 24 * 60 # crossed midnight
                        
                    diff_hours = round((out_total - in_total) / 60, 1)
                    hours_worked = diff_hours
                    
                    contracted = float(matched_user.get('contracted_hours_per_day') or 8.0)
                    if diff_hours > contracted:
                        overtime_mins = round((diff_hours - contracted) * 60)
                except:
                    pass
            
            records.append({
                "staff_email": matched_user['email'],
                "staff_name": matched_user['full_name'],
                "date": current_date,
                "check_in": in_time,
                "check_out": out_time,
                "status": "ON_TIME",
                "method": "BIOMETRIC",
                "hours_worked": hours_worked if out_time else None,
                "staff_type": matched_user.get('staff_type', 'FULL_TIME')
            })
            
    if records:
        print(f"Uploading {len(records)} records...")
        # Batch insert to avoid huge payloads
        batch_size = 50
        for i in range(0, len(records), batch_size):
            batch = records[i:i+batch_size]
            supabase.table('attendance_records').insert(batch).execute()
        print(f"Successfully processed {filename}!")
    else:
        print(f"No valid records found in {filename}.")

if __name__ == '__main__':
    process_file('9 June.xls')
    process_file('10 June.xls')
