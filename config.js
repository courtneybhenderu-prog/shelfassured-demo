// ShelfAssured Configuration
// Credentials are injected at build time via environment variables.
// NEVER hardcode API keys or URLs in this file.
// See .env.example for required variables.
window.SA_CONFIG = {
  SUPABASE_URL: typeof __VITE_SUPABASE_URL__ !== 'undefined' ? __VITE_SUPABASE_URL__ : '',
  SUPABASE_ANON_KEY: typeof __VITE_SUPABASE_ANON_KEY__ !== 'undefined' ? __VITE_SUPABASE_ANON_KEY__ : ''
};


