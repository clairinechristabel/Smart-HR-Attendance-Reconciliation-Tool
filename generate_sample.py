import pandas as pd
from datetime import datetime, timedelta

data = [
    {"Employee ID": "EMP-00142", "Date": "2026-06-18", "Clock In": "2026-06-18T08:02:00", "Clock Out": "2026-06-18T17:15:00", "Location": "Sham Shui Po Kitchen"},
    {"Employee ID": "EMP-00142", "Date": "2026-06-17", "Clock In": "2026-06-17T07:58:00", "Clock Out": "2026-06-17T17:05:00", "Location": "Sham Shui Po Kitchen"},
    {"Employee ID": "EMP-00142", "Date": "2026-06-16", "Clock In": "2026-06-16T08:32:00", "Clock Out": "2026-06-16T17:10:00", "Location": "Sham Shui Po Kitchen"},
    {"Employee ID": "EMP-00142", "Date": "2026-06-13", "Clock In": "2026-06-13T08:00:00", "Clock Out": "2026-06-13T17:00:00", "Location": "Sham Shui Po Kitchen"},
    {"Employee ID": "EMP-00088", "Date": "2026-06-18", "Clock In": "2026-06-18T09:30:00", "Clock Out": "", "Location": "Kwai Chung"},
    {"Employee ID": "EMP-00088", "Date": "2026-06-17", "Clock In": "2026-06-17T08:00:00", "Clock Out": "2026-06-17T16:00:00", "Location": "Kwai Chung"},
]

df = pd.DataFrame(data)
df.to_excel('sample_attendance.xlsx', index=False)
print("sample_attendance.xlsx created successfully!")
