import pandas as pd
from supabase import create_client, Client

url = "https://btzhzudlkrtiatdkbwpe.supabase.co"
key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ0emh6dWRsa3J0aWF0ZGtid3BlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODQxNzIsImV4cCI6MjA5Nzg2MDE3Mn0.eiRW8kVJFSocLiei3dqpVZhhZyxpEJLwT12rWHJa5NM"
supabase: Client = create_client(url, key)

df = pd.read_excel('9 June.xls', header=None)

# Get users
res = supabase.table('users').select('*').execute()
db_users = {u['full_name'].lower(): u for u in res.data}

updates = 0
for idx, row in df.iterrows():
    row_list = list(row.values)
    row_strs = [str(x).strip() if pd.notna(x) else "" for x in row_list]
    
    name = row_strs[0]
    if name and name not in ["User Name", "Daily In Out Report", ""] and "Date:" not in row_strs:
        dept = row_strs[6] if len(row_strs) > 6 else ""
        position = row_strs[8] if len(row_strs) > 8 else ""
        staff_code = row_strs[4] if len(row_strs) > 4 else ""
        
        user = db_users.get(name.lower())
        if user and (user.get('department') != dept or user.get('position') != position or user.get('employee_id') != staff_code):
            update_data = {}
            if dept: update_data['department'] = dept
            if position: update_data['position'] = position
            if staff_code: update_data['employee_id'] = staff_code
            
            if update_data:
                supabase.table('users').update(update_data).eq('email', user['email']).execute()
                updates += 1

print(f"Updated {updates} users with their correct department, position, and ID!")
