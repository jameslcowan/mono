-- Create metabase database for Metabase's internal storage
CREATE DATABASE metabase;

-- Create roles for PostgREST
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;

-- Grant usage to roles
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- API schema for cleaner separation (optional but recommended)
CREATE SCHEMA IF NOT EXISTS api;
GRANT USAGE ON SCHEMA api TO anon, authenticated;

-- Example: Training data table
CREATE TABLE api.training_samples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Core training data fields
    system_prompt TEXT,
    user_input TEXT NOT NULL,
    assistant_output TEXT NOT NULL,

    -- Metadata
    model_used VARCHAR(100),
    use_case VARCHAR(100),
    tags TEXT[],
    quality_score INTEGER CHECK (quality_score >= 1 AND quality_score <= 5),

    -- Versioning
    version INTEGER DEFAULT 1,
    is_approved BOOLEAN DEFAULT FALSE
);

-- Index for common queries
CREATE INDEX idx_training_samples_use_case ON api.training_samples(use_case);
CREATE INDEX idx_training_samples_approved ON api.training_samples(is_approved);
CREATE INDEX idx_training_samples_tags ON api.training_samples USING GIN(tags);

-- Grant access to roles
GRANT SELECT ON api.training_samples TO anon;
GRANT ALL ON api.training_samples TO authenticated;

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER training_samples_updated_at
    BEFORE UPDATE ON api.training_samples
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Helpful view for exports
CREATE VIEW api.approved_training_data AS
SELECT
    system_prompt,
    user_input,
    assistant_output,
    model_used,
    use_case
FROM api.training_samples
WHERE is_approved = TRUE;

GRANT SELECT ON api.approved_training_data TO anon, authenticated;

-- Comment for documentation
COMMENT ON TABLE api.training_samples IS 'LLM training data samples for fine-tuning';
