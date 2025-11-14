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

## 📊 Data Model

### Core Tables

#### 1. Users
Stores user profiles and preferences

```sql
- telegram_id (unique)
- name
- categories[] (job interests)
- profile (JSONB) - skills, experience, education
- gemini_api_key
- cv_generation_count
```

#### 2. Jobs
Aggregated job listings with AI analysis

```sql
- external_id (from RSS)
- title, company, description
- category, keywords[]
- experience_level
- application_contact
- status (active/expired)
```

#### 3. CV History
Tracks generated CVs for each application

```sql
- user_id
- job_id
- cv_content (markdown)
- matching_score
- created_at
```

#### 4. User Interactions
Analytics and user behavior tracking

```sql
- user_id
- action (registration, cv_upload, job_view, application)
- details (JSONB)
- timestamp
```

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
- **Supabase Project:** s8jolgx9

---

## 📄 License

This project is a proof-of-concept. Use at your own discretion.

---

## 🙏 Acknowledgments

- YemenHR.com for job listings
- Google Gemini for AI capabilities
- n8n for workflow automation
- Supabase for database infrastructure
- Telegram for bot platform

---

**Built with ❤️ for Yemeni job seekers**

*Last updated: November 2024*
