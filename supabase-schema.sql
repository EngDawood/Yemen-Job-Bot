-- Yemen Job Bot - Supabase Database Schema
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  telegram_id BIGINT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  username TEXT,
  categories TEXT[] DEFAULT ARRAY[]::TEXT[],
  gemini_api_key TEXT,
  profile JSONB DEFAULT '{}'::JSONB,
  original_cv_text TEXT,
  language_pref TEXT DEFAULT 'auto' CHECK (language_pref IN ('auto', 'ar', 'en', 'manual')),
  cv_generation_count INTEGER DEFAULT 0,
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. JOBS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS jobs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  external_id TEXT UNIQUE,
  title TEXT NOT NULL,
  company TEXT,
  description_raw TEXT,
  description_clean TEXT NOT NULL,
  details JSONB DEFAULT '{}'::JSONB,
  category TEXT,
  keywords TEXT[] DEFAULT ARRAY[]::TEXT[],
  language TEXT DEFAULT 'ar' CHECK (language IN ('ar', 'en', 'both')),
  experience_level TEXT CHECK (experience_level IN ('fresh', 'junior', 'mid', 'senior', 'any')),
  application_method TEXT DEFAULT 'email' CHECK (application_method IN ('email', 'form', 'link')),
  application_contact TEXT,
  source_url TEXT NOT NULL,
  posted_date TIMESTAMP WITH TIME ZONE,
  deadline TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'expired', 'filled')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 3. CV HISTORY TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS cv_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id) ON DELETE SET NULL,
  cv_content TEXT NOT NULL,
  cv_format TEXT DEFAULT 'markdown',
  matching_score NUMERIC(3,2),
  ai_model TEXT,
  generation_time_ms INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 4. USER INTERACTIONS TABLE (for analytics)
-- ============================================
CREATE TABLE IF NOT EXISTS user_interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}'::JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_telegram ON users(telegram_id);
CREATE INDEX IF NOT EXISTS idx_users_categories ON users USING GIN(categories);
CREATE INDEX IF NOT EXISTS idx_users_created ON users(created_at DESC);

-- Jobs indexes
CREATE INDEX IF NOT EXISTS idx_jobs_category ON jobs(category);
CREATE INDEX IF NOT EXISTS idx_jobs_keywords ON jobs USING GIN(keywords);
CREATE INDEX IF NOT EXISTS idx_jobs_posted ON jobs(posted_date DESC);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(status) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_jobs_language ON jobs(language);

-- CV History indexes
CREATE INDEX IF NOT EXISTS idx_cv_history_user ON cv_history(user_id);
CREATE INDEX IF NOT EXISTS idx_cv_history_job ON cv_history(job_id);
CREATE INDEX IF NOT EXISTS idx_cv_history_created ON cv_history(created_at DESC);

-- User Interactions indexes
CREATE INDEX IF NOT EXISTS idx_interactions_user ON user_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_action ON user_interactions(action);
CREATE INDEX IF NOT EXISTS idx_interactions_created ON user_interactions(created_at DESC);

-- ============================================
-- FULL TEXT SEARCH SETUP
-- ============================================

-- Add full text search for jobs
ALTER TABLE jobs ADD COLUMN IF NOT EXISTS search_vector tsvector;

CREATE OR REPLACE FUNCTION jobs_search_update() RETURNS trigger AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('arabic', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('arabic', COALESCE(NEW.company, '')), 'B') ||
    setweight(to_tsvector('arabic', COALESCE(NEW.description_clean, '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER jobs_search_update_trigger
  BEFORE INSERT OR UPDATE ON jobs
  FOR EACH ROW EXECUTE FUNCTION jobs_search_update();

CREATE INDEX IF NOT EXISTS idx_jobs_search ON jobs USING GIN(search_vector);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE cv_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_interactions ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (telegram_id = current_setting('request.jwt.claim.telegram_id', true)::bigint);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (telegram_id = current_setting('request.jwt.claim.telegram_id', true)::bigint);

CREATE POLICY "Service role full access users" ON users
  FOR ALL USING (current_setting('role', true) = 'service_role');

-- Jobs policies (public read)
CREATE POLICY "Jobs are viewable by all" ON jobs
  FOR SELECT USING (true);

CREATE POLICY "Service role full access jobs" ON jobs
  FOR ALL USING (current_setting('role', true) = 'service_role');

-- CV History policies
CREATE POLICY "Users can view own CV history" ON cv_history
  FOR SELECT USING (user_id IN (SELECT id FROM users WHERE telegram_id = current_setting('request.jwt.claim.telegram_id', true)::bigint));

CREATE POLICY "Service role full access cv_history" ON cv_history
  FOR ALL USING (current_setting('role', true) = 'service_role');

-- User Interactions policies
CREATE POLICY "Service role full access interactions" ON user_interactions
  FOR ALL USING (current_setting('role', true) = 'service_role');

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Function to get active jobs count
CREATE OR REPLACE FUNCTION get_active_jobs_count()
RETURNS INTEGER AS $$
BEGIN
  RETURN (SELECT COUNT(*) FROM jobs WHERE status = 'active');
END;
$$ LANGUAGE plpgsql;

-- Function to get user statistics
CREATE OR REPLACE FUNCTION get_user_stats(user_telegram_id BIGINT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_cvs_generated', COUNT(cv.*),
    'jobs_applied', COUNT(DISTINCT cv.job_id),
    'last_activity', MAX(u.last_active),
    'member_since', u.created_at,
    'is_premium', u.is_premium,
    'cv_limit_reached', u.cv_generation_count >= 5 AND NOT u.is_premium
  ) INTO result
  FROM users u
  LEFT JOIN cv_history cv ON cv.user_id = u.id
  WHERE u.telegram_id = user_telegram_id
  GROUP BY u.id, u.created_at, u.is_premium, u.cv_generation_count;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to mark old jobs as expired
CREATE OR REPLACE FUNCTION expire_old_jobs()
RETURNS INTEGER AS $$
DECLARE
  expired_count INTEGER;
BEGIN
  UPDATE jobs 
  SET status = 'expired'
  WHERE status = 'active'
    AND (deadline < NOW() OR posted_date < NOW() - INTERVAL '30 days');
  
  GET DIAGNOSTICS expired_count = ROW_COUNT;
  RETURN expired_count;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- INITIAL DATA (CATEGORIES)
-- ============================================

-- Create categories lookup (optional)
CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  keywords_ar TEXT[] DEFAULT ARRAY[]::TEXT[],
  keywords_en TEXT[] DEFAULT ARRAY[]::TEXT[]
);

INSERT INTO categories (id, name_ar, name_en, keywords_ar, keywords_en) VALUES
  ('IT', 'تقنية المعلومات', 'Information Technology', 
   ARRAY['برمجة', 'تطوير', 'شبكات', 'أمن معلومات'], 
   ARRAY['programming', 'development', 'networks', 'security']),
  ('Engineering', 'الهندسة', 'Engineering',
   ARRAY['مدني', 'كهرباء', 'ميكانيك'], 
   ARRAY['civil', 'electrical', 'mechanical']),
  ('Medical', 'الطب والصحة', 'Medical & Healthcare',
   ARRAY['طبيب', 'ممرض', 'صيدلي'], 
   ARRAY['doctor', 'nurse', 'pharmacist']),
  ('Finance', 'المالية والمحاسبة', 'Finance & Accounting',
   ARRAY['محاسب', 'مالي', 'مراجع'], 
   ARRAY['accountant', 'financial', 'auditor']),
  ('Marketing', 'التسويق والمبيعات', 'Marketing & Sales',
   ARRAY['تسويق', 'مبيعات', 'إعلان'], 
   ARRAY['marketing', 'sales', 'advertising']),
  ('Education', 'التعليم', 'Education',
   ARRAY['معلم', 'مدرس', 'مدرب'], 
   ARRAY['teacher', 'instructor', 'trainer']),
  ('Administration', 'الإدارة والموارد البشرية', 'Administration & HR',
   ARRAY['إداري', 'موارد بشرية', 'سكرتارية'], 
   ARRAY['admin', 'hr', 'secretary']),
  ('Other', 'أخرى', 'Other',
   ARRAY['متنوع'], 
   ARRAY['various'])
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- SETUP COMPLETE MESSAGE
-- ============================================
DO $$
BEGIN
  RAISE NOTICE 'Database schema setup completed successfully!';
  RAISE NOTICE 'Tables created: users, jobs, cv_history, user_interactions, categories';
  RAISE NOTICE 'Indexes and RLS policies configured';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '1. Configure n8n environment variables';
  RAISE NOTICE '2. Import n8n workflows';
  RAISE NOTICE '3. Test Telegram bot connection';
END $$;
