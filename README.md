# Yemen-Job-Bot
A Telegram bot that helps Yemeni job seekers find opportunities and generate tailored CVs using AI

## Features

- **Smart Job Matching** - AI-powered job recommendations based on user profiles
- **CV Generation** - Automated CV creation using Google Gemini AI
- **Daily Notifications** - Get notified about new matching jobs
- **Multi-Platform** - Fetch jobs from multiple sources
- **User Profiles** - Track skills, experience, and preferences
- **100% Free** - No costs for job seekers

## Tech Stack

- **Platform:** n8n (workflow automation)
- **Database:** Supabase (PostgreSQL)
- **Bot:** Telegram Bot API
- **AI:** Google Gemini API
- **Hosting:** n8n Cloud or Self-hosted

---

## Setup

### Prerequisites (5 minutes)

Before you begin, gather the following:

1. **Telegram Bot Token**
   - Message [@BotFather](https://t.me/BotFather) on Telegram
   - Create a new bot with `/newbot`
   - Save your bot token

2. **Supabase Account**
   - Sign up at [supabase.com](https://supabase.com)
   - Create a new project
   - Note your:
     - Project URL (format: `https://[ID].supabase.co`)
     - Anon/Public key
     - Service role secret key

3. **Google Gemini API Key**
   - Visit [Google AI Studio](https://aistudio.google.com)
   - Create API key
   - Save the key

4. **n8n Account**
   - Sign up at [n8n.io](https://n8n.io) (cloud)
   - OR self-host using Docker

---

### 1. Database Setup (5 minutes)

#### Step 1: Create Database Schema

1. Open your Supabase project
2. Go to **SQL Editor**
3. Create a new query
4. Copy and paste the following schema:

```sql
-- Users table
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  telegram_id BIGINT UNIQUE NOT NULL,
  username TEXT,
  full_name TEXT,
  phone TEXT,
  email TEXT,
  location TEXT,
  skills TEXT[],
  experience_years INTEGER,
  education_level TEXT,
  preferred_categories TEXT[],
  cv_file_id TEXT,
  gemini_api_key TEXT,
  notification_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Jobs table
CREATE TABLE jobs (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  company TEXT,
  description TEXT,
  location TEXT,
  category TEXT,
  salary_range TEXT,
  requirements TEXT[],
  source TEXT,
  source_url TEXT,
  posted_date TIMESTAMP WITH TIME ZONE,
  expires_date TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CV History table
CREATE TABLE cv_history (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  job_id BIGINT REFERENCES jobs(id),
  cv_content TEXT,
  generated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Interactions table
CREATE TABLE user_interactions (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT REFERENCES users(id),
  job_id BIGINT REFERENCES jobs(id),
  action TEXT, -- 'viewed', 'applied', 'saved', 'generated_cv'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Categories table
CREATE TABLE categories (
  id SERIAL PRIMARY KEY,
  name TEXT UNIQUE NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default categories
INSERT INTO categories (name, description) VALUES
  ('Technology', 'IT, Software, Hardware'),
  ('Healthcare', 'Medical, Nursing, Pharmacy'),
  ('Education', 'Teaching, Training, Academia'),
  ('Engineering', 'Civil, Mechanical, Electrical'),
  ('Business', 'Management, Sales, Marketing'),
  ('Finance', 'Banking, Accounting, Insurance'),
  ('Construction', 'Building, Architecture, Contracting'),
  ('Hospitality', 'Hotels, Tourism, Food Service'),
  ('Retail', 'Sales, Customer Service'),
  ('Other', 'Miscellaneous opportunities');

-- Create indexes for better performance
CREATE INDEX idx_users_telegram_id ON users(telegram_id);
CREATE INDEX idx_jobs_category ON jobs(category);
CREATE INDEX idx_jobs_is_active ON jobs(is_active);
CREATE INDEX idx_user_interactions_user_id ON user_interactions(user_id);
CREATE INDEX idx_user_interactions_job_id ON user_interactions(job_id);
```

5. Click **Run** to execute
6. Verify all 5 tables are created in the Table Editor

#### Step 2: Enable Row Level Security (Optional but Recommended)

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cv_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;

-- Create policies (users can only access their own data)
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid()::text = telegram_id::text);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid()::text = telegram_id::text);

-- Jobs are public (read-only for users)
CREATE POLICY "Jobs are viewable by everyone" ON jobs
  FOR SELECT USING (is_active = true);
```

---

### 2. n8n Configuration (10 minutes)

#### Step 1: Set Environment Variables

1. Login to your n8n instance
2. Go to **Settings** > **Variables** (or **Environment Variables** in self-hosted)
3. Add the following variables:

```
TELEGRAM_BOT_TOKEN=your_bot_token_here
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SECRET_KEY=your_service_role_key_here
GEMINI_API_KEY=your_gemini_key_here (optional - users can set their own)
```

#### Step 2: Add Telegram Credential

1. Go to **Credentials** > **Add Credential**
2. Search for "Telegram"
3. Select "Telegram API"
4. Enter your bot token
5. Click **Save**
6. Click **Test** to verify connection

---

### 3. Import Workflows (5 minutes)

You'll need to create 6 workflows. For now, create them manually:

#### Workflow 1: Registration Flow
- Trigger: Telegram webhook (`/start` command)
- Actions: Register user in Supabase, send welcome message

#### Workflow 2: CV Upload
- Trigger: Telegram file upload
- Actions: Store CV file ID, extract text, update user profile

#### Workflow 3: Job Fetcher (Scheduled)
- Trigger: Cron (daily at 9 AM)
- Actions: Scrape job sites, parse jobs, store in database

#### Workflow 4: Job Matching
- Trigger: On demand or scheduled
- Actions: Match jobs to users, send notifications

#### Workflow 5: CV Generation
- Trigger: User request
- Actions: Use Gemini AI to generate tailored CV

#### Workflow 6: Bot Commands
- Trigger: Telegram commands (`/jobs`, `/profile`, `/setapi`)
- Actions: Handle various bot commands

*Note: Detailed workflow JSON files will be provided in future updates.*

---

### 4. Activate Workflows (2 minutes)

In n8n, for each workflow:

1. Open the workflow
2. Click the toggle switch in the top-right
3. Ensure it turns **green** (active)
4. Verify "Active" badge appears

---

### 5. Test Your Bot (3 minutes)

#### Basic Tests

1. **Open Telegram** and search for your bot
2. **Send `/start`**
   - ✓ Should receive welcome message
   - ✓ Should be prompted for registration

3. **Complete registration**
   - ✓ Provide name, phone, skills, etc.
   - ✓ Should receive confirmation

4. **Upload a test CV** (PDF or DOCX)
   - ✓ Should receive upload confirmation
   - ✓ Check Supabase: `users` table should have `cv_file_id`

5. **Set Gemini API key**
   - Send `/setapi your_gemini_key`
   - ✓ Should receive confirmation

6. **Try `/jobs` command**
   - ✓ Should receive job listings (if any in database)

7. **Generate test CV**
   - Send `/generatecv [job_id]`
   - ✓ Should receive AI-generated CV

---

### 6. Troubleshooting

#### Bot not responding

```
✓ Check workflows are activated (green toggle in n8n)
✓ Verify TELEGRAM_BOT_TOKEN is correct in environment variables
✓ Check n8n execution logs for errors
✓ Ensure webhook is properly configured
```

#### Database errors

```
✓ Verify Supabase URL format: https://[ID].supabase.co
✓ Check both API keys (anon and secret) are saved correctly
✓ Ensure all 5 tables exist in Supabase
✓ Check RLS policies if enabled
```

#### CV generation fails

```
✓ User must upload CV first using /profile
✓ User must set Gemini API key using /setapi
✓ Check Gemini API quota and billing
✓ Verify API key is valid
```

#### Jobs not appearing

```
✓ Check if job fetcher workflow is activated
✓ Verify jobs exist in database (check Supabase Table Editor)
✓ Ensure jobs have is_active = true
✓ Check cron schedule is configured correctly
```

---

## Deployment Checklist

Use this to verify your setup is complete:

### Database
- [ ] All 5 tables created in Supabase
- [ ] Default categories inserted
- [ ] Indexes created
- [ ] RLS policies enabled (optional)
- [ ] Test query works

### n8n
- [ ] Environment variables configured
- [ ] Telegram credential added and tested
- [ ] All 6 workflows created
- [ ] All workflows activated (green toggle)
- [ ] Webhook URLs configured

### Bot Testing
- [ ] Bot responds to `/start`
- [ ] Registration flow works
- [ ] CV upload works
- [ ] Commands work (`/jobs`, `/profile`, `/setapi`)
- [ ] Job matching works
- [ ] CV generation works

---

## Next Steps

1. **Invite Test Users** - Have 2-3 people test the full journey
2. **Monitor Logs** - Check n8n execution logs daily for first week
3. **Gather Feedback** - Iterate on bot messages and AI prompts
4. **Add Job Sources** - Integrate more job boards and websites
5. **Scale** - Plan Phase 2 features (web interface, analytics, etc.)

---

## Support

- **Documentation:** Check workflow comments in n8n
- **Issues:** Contact [@Daw5d](https://t.me/Daw5d) on Telegram
- **Community:** Join n8n community forum for workflow help

---

## License

MIT License - Feel free to use and modify for your needs

---

**Last Updated:** November 2024
**Version:** 1.0 (POC)
