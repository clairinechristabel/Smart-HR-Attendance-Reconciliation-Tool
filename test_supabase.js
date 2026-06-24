const SUPABASE_URL = 'https://btzhzudlkrtiatdkbwpe.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ0emh6dWRsa3J0aWF0ZGtid3BlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODQxNzIsImV4cCI6MjA5Nzg2MDE3Mn0.eiRW8kVJFSocLiei3dqpVZhhZyxpEJLwT12rWHJa5NM';
fetch(SUPABASE_URL + '/rest/v1/users?select=*', {
  headers: {
    'apikey': SUPABASE_KEY,
    'Authorization': 'Bearer ' + SUPABASE_KEY
  }
}).then(res => res.json()).then(data => {
  console.log("Supabase Response:");
  console.log(data);
}).catch(console.error);
