const SUPABASE_URL = 'https://btzhzudlkrtiatdkbwpe.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ0emh6dWRsa3J0aWF0ZGtid3BlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIyODQxNzIsImV4cCI6MjA5Nzg2MDE3Mn0.eiRW8kVJFSocLiei3dqpVZhhZyxpEJLwT12rWHJa5NM';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);

// Helper function to show toasts globally
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = 'floating-toast ' + type;
    toast.innerHTML = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 4000);
}
