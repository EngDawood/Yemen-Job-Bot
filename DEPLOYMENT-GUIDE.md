# Yemen Job Bot - Complete Setup Guide

## 📋 Prerequisites

Before starting, make sure you have:

1. ✅ n8n account (cloud or self-hosted)
2. ✅ Telegram account
3. ✅ Supabase account (free tier)
4. ✅ Google Gemini API key

---

## 🚀 Step-by-Step Setup

### Step 1: Create Telegram Bot

1. Open Telegram and search for `@BotFather`
2. Send `/newbot` command
3. Follow instructions:
   - Bot name: `Yemen Job Bot` (or your choice)
   - Bot username: `@YemenhrBot` (must end with 'bot')
4. **Save the token** (looks like: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. Set bot commands:
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

### Step 2: Setup Supabase

1. Go to [supabase.com](https://supabase.com)
2. Create new project:
   - Name: `yemen-job-bot`
   - Database password: (create strong password)
   - Region: Choose closest to Yemen
3. Wait for project to provision (2-3 minutes)
4. Copy your credentials:
   - Project URL: `https://[PROJECT_ID].supabase.co`
   - Anon/Public Key: `sb_publishable_...`
   - Service Role Key: `sb_secret_...` (**Keep this secret!**)

5. **Run Database Schema:**
   - Go to SQL Editor in Supabase dashboard
   - Copy content from `supabase-schema.sql`
   - Paste and execute
   - Verify tables created: users, jobs, cv_history, user_interactions, categories

### Step 3: Get Gemini API Key

1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Sign in with Google account
3. Click "Get API Key"
4. Create new API key
5. **Save the key** (starts with `AI...`)

### Step 4: Setup n8n

#### Option A: n8n Cloud (Recommended)

1. Go to [n8n.cloud](https://n8n.cloud)
2. Sign up for free account
3. Create new workflow

#### Option B: Self-Hosted n8n

```bash
# Using Docker
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Access at: http://localhost:5678
```

### Step 5: Configure n8n Environment Variables

1. In n8n, go to **Settings** > **Variables**
2. Add these variables:

```bash
# Supabase
SUPABASE_URL = https://s8jolgx9.supabase.co
SUPABASE_ANON_KEY = sb_publishable_4D0t7ivoNYPjrdX5uxWjbQ_s8jolgx9
SUPABASE_SECRET_KEY = sb_secret_A9tOMZfv-ZlFmE2vAJO9bg_UcRVK5xv

# Telegram
TELEGRAM_BOT_TOKEN = [YOUR_BOT_TOKEN_FROM_BOTFATHER]
TELEGRAM_BOT_USERNAME = @Yemenhrbot
ADMIN_TELEGRAM_ID = 801062947

# Gemini (for job processing)
ADMIN_GEMINI_KEY = [YOUR_GEMINI_API_KEY]

# YemenHR
YEMENHR_RSS_URL = https://yemenhr.com/feed
YEMENHR_BASE_URL = https://yemenhr.com
```

### Step 6: Setup Telegram Credentials in n8n

1. Go to **Credentials** in n8n
2. Click **Add Credential**
3. Select **Telegram API**
4. Enter:
   - Credential Name: `Telegram Bot API`
   - Access Token: [YOUR_BOT_TOKEN]
5. Click **Save**

### Step 7: Import Workflows

Import each workflow file in this order:

1. **Registration Workflow**
   - File: `workflow-1-registration.json`
   - Import in n8n: Workflows > Import from File
   - Activate workflow

2. **CV Upload Workflow**
   - File: `workflow-2-cv-upload.json`
   - Import and activate

3. **Job Fetcher Workflow**
   - File: `workflow-3-job-fetcher.json`
   - Import and activate
   - This runs every hour automatically

4. **Job Matching Workflow**
   - File: `workflow-4-job-matching.json`
   - Import and activate
   - Runs daily at 9 AM

5. **CV Generation Workflow**
   - File: `workflow-5-cv-generation.json`
   - Import and activate

6. **Bot Commands Workflow**
   - File: `workflow-6-bot-commands.json`
   - Import and activate

### Step 8: Update Telegram Webhooks

After importing workflows:

1. Each workflow with Telegram trigger will have a webhook URL
2. n8n automatically registers webhooks with Telegram
3. Test by sending `/start` to your bot

---

## 🧪 Testing the Bot

### Test 1: Registration

1. Open Telegram and search for your bot
2. Send `/start`
3. Expected: Welcome message with buttons
4. Click "تسجيل جديد"
5. Enter your name
6. Select categories
7. Confirm selection
8. Check Supabase: users table should have new entry

### Test 2: CV Upload

1. Send `/profile`
2. Upload a CV file (PDF or text)
3. Wait 10-15 seconds
4. Expected: "تم تحليل سيرتك الذاتية بنجاح!"
5. Check Supabase: users table should have profile data

### Test 3: API Key Setup

1. Get a Gemini API key from aistudio.google.com
2. Send `/setapi YOUR_API_KEY`
3. Expected: "تم حفظ مفتاح Gemini API بنجاح!"

### Test 4: Job Fetching

1. Manually trigger "Job Fetcher Workflow"
2. Check n8n execution logs
3. Check Supabase: jobs table should have entries
4. Check Telegram: Admin should receive notification

### Test 5: View Jobs

1. Send `/jobs`
2. Expected: List of matching jobs
3. Send `/alljobs`
4. Expected: List of all available jobs

### Test 6: CV Generation

1. Send `/apply` with job ID (e.g., `/apply_uuid`)
2. Wait 15-20 seconds
3. Expected: PDF file sent to Telegram
4. Check Supabase: cv_history table should have entry

### Test 7: View History

1. Send `/history`
2. Expected: List of generated CVs with timestamps

---

## 🐛 Troubleshooting

### Bot Not Responding

**Problem:** Bot doesn't reply to commands

**Solutions:**
1. Check n8n workflows are activated (green toggle)
2. Verify TELEGRAM_BOT_TOKEN is correct
3. Check n8n execution logs for errors
4. Test webhook URL in browser
5. Restart workflows

### Database Connection Errors

**Problem:** "Connection to Supabase failed"

**Solutions:**
1. Verify SUPABASE_URL is correct
2. Check API keys are correct
3. Verify RLS policies in Supabase
4. Check project is not paused (free tier)

### CV Generation Fails

**Problem:** "Failed to generate CV"

**Solutions:**
1. Verify user has uploaded CV first
2. Check Gemini API key is valid
3. Verify user's Gemini API key has quota
4. Check n8n logs for exact error
5. Test Gemini API directly

### Jobs Not Fetching

**Problem:** No new jobs in database

**Solutions:**
1. Verify RSS feed URL is accessible
2. Check ADMIN_GEMINI_KEY is valid
3. Look at Job Fetcher workflow logs
4. Test RSS feed manually in browser
5. Check Gemini API quota

### Matching Algorithm Not Working

**Problem:** Users not receiving job notifications

**Solutions:**
1. Check user has categories selected
2. Verify jobs have correct categories
3. Check Job Matching workflow schedule
4. Look at workflow execution logs
5. Test matching logic with sample data

---

## 📊 Monitoring & Analytics

### n8n Monitoring

1. Go to **Executions** tab
2. Filter by workflow
3. Check success/failure rates
4. Review error messages

### Supabase Monitoring

1. Go to **Database** > **Table Editor**
2. Check record counts:
   - Users: Active registrations
   - Jobs: Active job listings
   - CV History: Generated CVs
   - User Interactions: Activity logs

3. Go to **Logs** for API requests

### Telegram Admin Notifications

You'll receive notifications for:
- ✅ New jobs fetched
- ✅ Daily matching complete
- ❌ Errors in workflows

---

## 🔒 Security Best Practices

1. **API Keys:**
   - Never commit keys to version control
   - Use n8n's encrypted credential storage
   - Rotate keys regularly

2. **Supabase:**
   - Enable RLS (Row Level Security)
   - Use SUPABASE_SECRET_KEY only in backend
   - Monitor API usage

3. **Telegram:**
   - Don't share bot token publicly
   - Implement rate limiting
   - Validate user inputs

4. **n8n:**
   - Use strong authentication
   - Enable 2FA if available
   - Restrict workflow editing access

---

## 📈 Scaling Considerations

### When You Grow

**Free Tier Limits:**
- Supabase: 500MB database, 2GB bandwidth
- n8n Cloud: 20 workflows, 200 executions/month
- Gemini: Rate limits apply

**Upgrade Path:**
1. Supabase Pro: $25/month (8GB database, 250GB bandwidth)
2. n8n Pro: $20/month (unlimited workflows)
3. Consider caching frequently accessed data
4. Implement database indexing
5. Add Redis for session management

### Performance Optimization

1. **Database:**
   - Add more indexes for frequent queries
   - Use database functions for complex logic
   - Archive old CV history

2. **Workflows:**
   - Batch process users in matching
   - Cache job data
   - Implement exponential backoff for retries

3. **Bot:**
   - Add rate limiting
   - Implement command cooldowns
   - Queue CV generation requests

---

## 🎯 Next Steps & Enhancements

### Phase 2 Features (Future)

1. **Email Integration:**
   - Direct application via email
   - SMTP configuration per user
   - Application tracking

2. **Advanced Matching:**
   - ML-based skill matching
   - Salary expectations
   - Location preferences
   - Company ratings

3. **Tender Module:**
   - Fetch tenders from yemenhr.com
   - Match with contractors
   - Bid templates generation

4. **Subscription System:**
   - Free tier: 5 CVs/month
   - Premium: Unlimited CVs
   - Payment integration (Stripe)

5. **Web Interface:**
   - Dashboard for users
   - Company portal
   - Admin panel

6. **Mobile Apps:**
   - iOS and Android
   - Push notifications
   - Offline mode

---

## 📞 Support

For issues or questions:

- **Developer:** @Daw5d on Telegram
- **Bot:** @Yemenhrbot
- **Documentation:** This guide
- **n8n Community:** community.n8n.io
- **Supabase Docs:** supabase.com/docs

---

## ✅ Deployment Checklist

Before going live:

- [ ] All workflows imported and activated
- [ ] Environment variables configured
- [ ] Database schema deployed
- [ ] Telegram bot created and connected
- [ ] Admin notifications working
- [ ] All tests passing
- [ ] Error handling tested
- [ ] Backup strategy in place
- [ ] Monitoring setup
- [ ] Documentation reviewed

---

## 🎉 Congratulations!

Your Yemen Job Bot is now live! Users can:

- Register and create profiles
- Upload CVs for smart matching
- Receive daily job notifications
- Generate tailored CVs with AI
- Apply to jobs with one click

**Remember:** This is a POC. Monitor usage, gather feedback, and iterate based on user needs.

Good luck with your platform! 🚀🇾🇪
