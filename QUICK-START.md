# Yemen Job Bot - Quick Start Checklist

Use this checklist to deploy your bot in under 30 minutes.

## ⚡ Quick Setup (30 minutes)

### 1. Prerequisites (5 minutes)

- [ ] Create Telegram bot via @BotFather
- [ ] Note bot token: `_________________________`
- [ ] Create Supabase project
- [ ] Note Supabase URL: `_________________________`
- [ ] Note Supabase anon key: `_________________________`
- [ ] Note Supabase secret key: `_________________________`
- [ ] Get Gemini API key from aistudio.google.com
- [ ] Note Gemini key: `_________________________`
- [ ] Sign up for n8n (cloud or self-hosted)

### 2. Database Setup (5 minutes)

- [ ] Open Supabase SQL Editor
- [ ] Copy content from `supabase-schema.sql`
- [ ] Execute SQL
- [ ] Verify 5 tables created:
  - [ ] users
  - [ ] jobs
  - [ ] cv_history
  - [ ] user_interactions
  - [ ] categories

### 3. n8n Configuration (10 minutes)

- [ ] Login to n8n
- [ ] Go to Settings > Variables
- [ ] Add all environment variables from `n8n-env-config.md`
- [ ] Go to Credentials
- [ ] Add Telegram API credential with bot token
- [ ] Test credential

### 4. Import Workflows (5 minutes)

Import in this order:

- [ ] workflow-1-registration.json
- [ ] workflow-2-cv-upload.json
- [ ] workflow-3-job-fetcher.json
- [ ] workflow-4-job-matching.json
- [ ] workflow-5-cv-generation.json
- [ ] workflow-6-bot-commands.json

### 5. Activate Workflows (2 minutes)

- [ ] Activate workflow 1 (Registration)
- [ ] Activate workflow 2 (CV Upload)
- [ ] Activate workflow 3 (Job Fetcher)
- [ ] Activate workflow 4 (Job Matching)
- [ ] Activate workflow 5 (CV Generation)
- [ ] Activate workflow 6 (Bot Commands)

### 6. Test Bot (3 minutes)

- [ ] Open Telegram
- [ ] Search for your bot
- [ ] Send `/start`
- [ ] Complete registration
- [ ] Upload test CV
- [ ] Add Gemini API key
- [ ] Try `/jobs` command
- [ ] Generate test CV

---

## 🐛 Common Issues & Quick Fixes

### Bot not responding
```
✓ Check workflows are activated (green toggle)
✓ Verify TELEGRAM_BOT_TOKEN is correct
✓ Check n8n execution logs
```

### Database errors
```
✓ Verify Supabase URL format: https://[ID].supabase.co
✓ Check both API keys are saved
✓ Ensure RLS policies are created
```

### CV generation fails
```
✓ User must upload CV first (/profile)
✓ User must set Gemini API key (/setapi)
✓ Check Gemini API quota
```

---

## 📊 Verify Setup

All green = Ready to launch! 🚀

**Database:**
- [ ] All tables exist in Supabase
- [ ] Sample query works
- [ ] RLS policies enabled

**n8n:**
- [ ] All 6 workflows imported
- [ ] All workflows activated
- [ ] Environment variables set
- [ ] Telegram credential added

**Bot:**
- [ ] Bot responds to /start
- [ ] Registration works
- [ ] CV upload works
- [ ] Commands work

---

## 🎯 Next Steps After Setup

1. **Test with Real Users:**
   - Invite 2-3 test users
   - Have them complete full journey
   - Collect feedback

2. **Monitor First Week:**
   - Check n8n execution logs daily
   - Monitor Supabase usage
   - Track error rates
   - Review user feedback

3. **Optimize:**
   - Adjust matching algorithm based on feedback
   - Refine AI prompts for better CVs
   - Improve bot messages

4. **Scale:**
   - Document learnings
   - Plan Phase 2 features
   - Consider web interface
   - Explore monetization

---

## 📞 Need Help?

- Check DEPLOYMENT-GUIDE.md for detailed instructions
- Review README.md for architecture details
- Contact @Daw5d on Telegram
- Join n8n community forum

---

## 🎉 Deployment Complete!

Your Yemen Job Bot is now live and helping job seekers!

**Share your bot:**
```
Try our AI-powered job matching bot! 
👉 @YemenhrBot

Features:
✅ Smart job matching
✅ AI-generated CVs
✅ Daily notifications
✅ 100% Free

Get started: /start
```

---

**Last updated:** November 2024
**Version:** 1.0 (POC)
