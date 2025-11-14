# Yemen Job Bot - AI-Powered Job Matching & CV Generation

> A Telegram bot that helps Yemeni job seekers find opportunities and generate tailored CVs using AI

## 🎯 Project Overview

This is a proof-of-concept (POC) for an automated job matching and CV generation platform built entirely with no-code tools. The system helps job seekers in Yemen discover relevant opportunities and apply with AI-optimized resumes.

### Key Features

- 🤖 **Automated Job Aggregation** - Fetches jobs from YemenHR.com via RSS
- 🎯 **Smart Job Matching** - AI-powered matching based on skills, experience, and preferences
- 📄 **AI CV Generation** - Creates ATS-optimized CVs tailored to each job
- 📱 **Telegram Interface** - Easy-to-use bot interface for all interactions
- 🔄 **Daily Notifications** - Users receive matching jobs every morning
- 📊 **Analytics Dashboard** - Track usage and optimize matching algorithms

---

## 🏗️ Architecture

### Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Bot Interface** | Telegram Bot API | User interaction |
| **Workflow Engine** | n8n | Automation and orchestration |
| **Database** | Supabase (PostgreSQL) | Data storage |
| **AI Engine** | Google Gemini API | CV parsing, job analysis, CV generation |
| **Job Source** | YemenHR.com RSS | Job listings feed |

### System Architecture

```
┌─────────────┐
│   Telegram  │◄──── Users interact via bot commands
│     Bot     │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│             n8n Workflows                │
│  ┌───────────────────────────────────┐  │
│  │  1. Registration & Onboarding     │  │
│  │  2. CV Upload & Profile Building  │  │
│  │  3. Job Fetching & Processing     │  │
│  │  4. Smart Job Matching            │  │
│  │  5. CV Generation & Delivery      │  │
│  │  6. Bot Commands & Utilities      │  │
│  └───────────────────────────────────┘  │
└──────┬────────────────┬─────────────────┘
       │                │
       ▼                ▼
┌─────────────┐  ┌──────────────┐
│   Supabase  │  │ Gemini API   │
│  (Database) │  │ (AI Engine)  │
└─────────────┘  └──────────────┘
       ▲
       │
┌──────┴──────┐
│  YemenHR    │
│  RSS Feed   │
└─────────────┘
```

---

## 🚀 Quick Setup (30 minutes)

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

You'll need to create 6 workflows:

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

## 📊 Deployment Checklist

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

## 🔄 User Journey

### 1. Registration (1 minute)
```
User → /start
     → Enter name
     → Select job categories
     → Registration complete ✓
```

### 2. Profile Setup (2-3 minutes)
```
User → /profile
     → Upload CV (PDF/Text)
     → AI extracts: skills, education, experience
     → Profile created ✓
```

### 3. API Key Setup (1 minute)
```
User → /setapi [key]
     → Gemini API key saved
     → Ready to generate CVs ✓
```

### 4. Daily Job Matching (Automatic)
```
System → Fetch new jobs (hourly)
       → Analyze with AI
       → Match with users
       → Send notifications (9 AM daily)
```

### 5. CV Generation & Application (30 seconds)
```
User → /apply [job_id]
     → AI analyzes job requirements
     → Generates tailored CV
     → Delivers PDF to user
     → User applies manually ✓
```

---

## 🔑 Key Workflows

### 1. Registration Workflow
- Captures user basic info
- Collects job category preferences
- Creates database record
- Offers CV upload

### 2. CV Upload Workflow
- Accepts PDF, Word, or text
- Extracts text content
- Parses with Gemini AI
- Stores structured profile

### 3. Job Fetcher Workflow
**Runs: Every hour**
- Fetches RSS feed from YemenHR
- Cleans HTML content
- Analyzes with AI to extract:
  - Company name
  - Job category
  - Required skills
  - Experience level
  - Application method
- Saves to database

### 4. Job Matching Workflow
**Runs: Daily at 9 AM**
- Retrieves all active users
- For each user:
  - Fetches jobs from their categories
  - Calculates match score (0-100):
    - Category match: 40 points
    - Skills match: 30 points
    - Experience match: 20 points
    - Language match: 10 points
  - Sends top 5 matches via Telegram

### 5. CV Generation Workflow
**Triggered: User command**
- Validates user has profile and API key
- Retrieves job requirements
- Prepares context for AI
- Calls Gemini to generate CV:
  - ATS-optimized format
  - Highlights relevant experience
  - Matches job keywords
  - Professional structure
- Converts Markdown to PDF
- Sends to user via Telegram
- Saves to history

### 6. Bot Commands Workflow
Handles utility commands:
- `/help` - Shows all commands
- `/jobs` - Lists matching jobs
- `/alljobs` - Browse all jobs
- `/history` - View CV history
- `/setapi` - Configure API key

---

## 🎯 Smart Matching Algorithm

### Scoring System

```javascript
Total Score = Category (40%) + Skills (30%) + Experience (20%) + Language (10%)

Category Match (40 points):
- User categories contain job category: +40

Skills Match (30 points):
- Per matching skill: +10 (max 30)
- Fuzzy matching: "Python" matches "programming"

Experience Match (20 points):
- Fresh (0-1 years): fresh jobs only
- Junior (1-3 years): junior + fresh jobs
- Mid (3-7 years): mid + junior jobs
- Senior (7+ years): any level

Language Match (10 points):
- Arabic user + Arabic job: +10
- English user + English job: +10
- Any user + bilingual job: +10
```

### Filtering Rules

1. **Minimum Score:** 40/100 (category match required)
2. **Maximum Results:** Top 5 jobs per notification
3. **Recency:** Jobs from last 24 hours prioritized
4. **Duplicates:** Same job not sent twice

---

## 💡 AI Prompts

### CV Parsing Prompt
```
Extract structured information from this CV.
Return valid JSON with:
- Personal info (name, email, phone)
- Skills array
- Education array (degree, institution, year)
- Experience array (title, company, duration, achievements)
- Certifications array
- Total years of experience
```

### Job Analysis Prompt
```
Analyze this job posting and extract:
- Company name
- Job category (IT, Engineering, Medical, etc.)
- Required skills array
- Experience level (fresh, junior, mid, senior)
- Application method (email, form, link)
- Application contact
- Language (Arabic, English, both)
```

### CV Generation Prompt
```
Create ATS-optimized CV in [language] matching:

User Profile: [skills, experience, education]
Job Requirements: [title, company, skills, keywords]

Format:
- Professional summary (2-3 sentences)
- Core skills (6-10 relevant)
- Experience (highlight achievements)
- Education
- Languages

Requirements:
- Match job keywords
- Emphasize relevant experience
- Professional formatting
- 1-2 pages maximum
```

---

## 📈 Analytics & Monitoring

### Key Metrics

1. **User Metrics:**
   - Total registrations
   - Active users (7-day, 30-day)
   - Profile completion rate
   - API key setup rate

2. **Job Metrics:**
   - Jobs fetched per day
   - Job categories distribution
   - Average match score
   - Jobs per notification

3. **CV Metrics:**
   - CVs generated per day
   - Average generation time
   - Success rate
   - User rating (future)

4. **System Metrics:**
   - Workflow execution success rate
   - API usage (Gemini, Supabase)
   - Error rate
   - Response time

### Admin Notifications

Admins receive daily reports:
```
📊 Daily Summary
👥 New Users: 5
📄 Jobs Added: 12
📝 CVs Generated: 23
✅ Success Rate: 98%
```

---

## 🔒 Security & Privacy

### Data Protection

1. **API Keys:** Encrypted at rest in database
2. **User Data:** RLS policies enforce access control
3. **CVs:** Stored temporarily, auto-deleted after 90 days
4. **No Tracking:** No third-party analytics

### User Privacy

- Users control their data
- Can delete profile anytime
- No data sold or shared
- Gemini API uses user's own key (user has control)

---

## 💰 Cost Analysis (Monthly)

### Free Tier Usage

| Service | Free Tier | Estimated Usage | Cost |
|---------|-----------|----------------|------|
| Supabase | 500MB DB | ~100MB | $0 |
| n8n Cloud | 200 executions | ~150 | $0 |
| Gemini API | Rate limited | User-provided keys | $0 |
| **Total** | | | **$0/month** |

### Paid Tier (100+ users)

| Service | Plan | Cost |
|---------|------|------|
| Supabase Pro | 8GB DB | $25 |
| n8n Pro | Unlimited | $20 |
| Gemini Admin | Job processing | ~$10 |
| **Total** | | **~$55/month** |

---

## 🚀 Future Enhancements

### Phase 2 (1-2 months)

- [ ] Email automation for direct applications
- [ ] Multiple CV templates
- [ ] Company ratings and reviews
- [ ] Salary insights
- [ ] Interview preparation tips

### Phase 3 (3-6 months)

- [ ] Web dashboard
- [ ] Mobile apps (iOS, Android)
- [ ] Tender/contract module
- [ ] Subscription tiers
- [ ] B2B company accounts

### Phase 4 (6-12 months)

- [ ] Advanced ML matching
- [ ] Video CV generation
- [ ] Interview scheduling
- [ ] Applicant tracking system
- [ ] Recruitment marketplace

---

## 📚 Documentation Files

1. **DEPLOYMENT-GUIDE.md** - Complete setup instructions
2. **n8n-env-config.md** - Environment variables
3. **supabase-schema.sql** - Database schema
4. **workflow-1-registration.json** - User registration
5. **workflow-2-cv-upload.json** - CV parsing
6. **workflow-3-job-fetcher.json** - Job aggregation
7. **workflow-4-job-matching.json** - Smart matching
8. **workflow-5-cv-generation.json** - CV creation
9. **workflow-6-bot-commands.json** - Bot utilities

---

## 🤝 Contributing

This is a POC project. For production deployment:

1. Implement proper error handling
2. Add rate limiting
3. Implement caching layer
4. Add comprehensive logging
5. Setup CI/CD pipeline
6. Add automated testing
7. Implement backup strategy

---

## 📞 Contact & Support

- **Developer:** @Daw5d (Telegram)
- **Bot:** @Yemenhrbot
- **Documentation:** Check workflow comments in n8n
- **Issues:** Contact [@Daw5d](https://t.me/Daw5d) on Telegram
- **Community:** Join n8n community forum for workflow help

---

## 📄 License

MIT License - Feel free to use and modify for your needs

---

## 🙏 Acknowledgments

- YemenHR.com for job listings
- Google Gemini for AI capabilities
- n8n for workflow automation
- Supabase for database infrastructure
- Telegram for bot platform

---

**Built with ❤️ for Yemeni job seekers**

**Last Updated:** November 2024 | **Version:** 1.0 (POC)
