# n8n Environment Variables Configuration

## Required Environment Variables

Add these to your n8n instance (Settings > Variables):

```bash
# Supabase Configuration
SUPABASE_URL=https://s8jolgx9.supabase.co
SUPABASE_ANON_KEY=sb_publishable_4D0t7ivoNYPjrdX5uxWjbQ_s8jolgx9
SUPABASE_SECRET_KEY=sb_secret_A9tOMZfv-ZlFmE2vAJO9bg_UcRVK5xv

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=<YOUR_BOT_TOKEN_FROM_BOTFATHER>
TELEGRAM_BOT_USERNAME=@Yemenhrbot
ADMIN_TELEGRAM_ID=801062947

# API Keys (User will provide their own Gemini key)
ADMIN_GEMINI_KEY=<YOUR_GEMINI_KEY_FOR_JOB_PROCESSING>

# YemenHR Configuration
YEMENHR_RSS_URL=https://yemenhr.com/feed
YEMENHR_BASE_URL=https://yemenhr.com

# System Settings
DEFAULT_LANGUAGE=ar
MAX_FREE_CVS=5
JOB_FETCH_INTERVAL=3600
```

## How to Get Telegram Bot Token

1. Open Telegram and search for @BotFather
2. Send `/newbot` command
3. Follow instructions to create bot
4. Copy the token provided
5. Set bot commands using:
```
/setcommands

start - البدء واستخدام البوت
register - التسجيل في النظام
profile - رفع أو تحديث السيرة الذاتية
setapi - إضافة مفتاح Gemini API
jobs - عرض الوظائف المطابقة لك
alljobs - عرض جميع الوظائف الأخيرة
apply - توليد سيرة ذاتية لوظيفة معينة
history - عرض السير الذاتية المولدة
help - عرض المساعدة
```

## How to Get Gemini API Key

1. Visit https://aistudio.google.com/
2. Click "Get API Key"
3. Create new API key
4. Copy and save securely

## Security Notes

- Never commit API keys to version control
- Use n8n's encrypted credentials feature
- Rotate keys regularly
- Use SUPABASE_SECRET_KEY only in server workflows
- Use SUPABASE_ANON_KEY for client operations with RLS enabled
