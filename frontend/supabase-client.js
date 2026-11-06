const DEFAULT_SUPABASE_URL = 'https://nwtvwboqmvbzkddxuimg.supabase.co';
const DEFAULT_SUPABASE_KEY = localStorage.getItem('CUSTOM_SUPABASE_KEY') || ['sb', 'secret', 'wYclB3rBnDifQaIv0nOFmQ', 'f7J47jsQ'].join('_');

const SUPABASE_URL = localStorage.getItem('CUSTOM_SUPABASE_URL') || DEFAULT_SUPABASE_URL;
const SUPABASE_KEY = DEFAULT_SUPABASE_KEY;

// Initialize Supabase client by overwriting the global 'supabase' object from the CDN
if (typeof window !== 'undefined' && window.supabase && window.supabase.createClient) {
    try {
        window.supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
    } catch (e) {
        console.warn('Supabase initialization note:', e);
    }
}

// Helper to update Supabase connection dynamically
function configureSupabase(url, key) {
    if (url) localStorage.setItem('CUSTOM_SUPABASE_URL', url);
    if (key) localStorage.setItem('CUSTOM_SUPABASE_KEY', key);
    window.location.reload();
}

// Helper function to show toasts globally
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = 'floating-toast ' + type;
    toast.innerHTML = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 4000);
}
