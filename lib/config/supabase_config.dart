class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pbdwkilckvkwmbysibsi.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBiZHdraWxja3Zrd21ieXNpYnNpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA0Nzc4OTksImV4cCI6MjEwNjA1Mzg5OX0.r895ByiwoHFJgBIujEohObqolY0VlY0EWeLdYYSPUUY',
  );
}
