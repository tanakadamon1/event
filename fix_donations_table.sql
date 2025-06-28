-- Fix donations table - add missing columns if table exists
-- If table doesn't exist, create it

-- First, check if donations table exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'donations') THEN
        -- Create donations table if it doesn't exist
        CREATE TABLE donations (
            id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
            donor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            recipient_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            event_id UUID REFERENCES events(id) ON DELETE CASCADE,
            amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
            currency VARCHAR(3) DEFAULT 'JPY',
            paypay_payment_id VARCHAR(255) UNIQUE,
            paypay_merchant_payment_id VARCHAR(255),
            paypay_qr_code_url TEXT,
            status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled', 'expired')),
            message TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
        );

        -- Enable RLS
        ALTER TABLE donations ENABLE ROW LEVEL SECURITY;

        -- Create policies
        CREATE POLICY "Users can view their own donations" ON donations
            FOR SELECT USING (auth.uid() = donor_id OR auth.uid() = recipient_id);

        CREATE POLICY "Users can create donations" ON donations
            FOR INSERT WITH CHECK (auth.uid() = donor_id);

        CREATE POLICY "Users can update their own donations" ON donations
            FOR UPDATE USING (auth.uid() = donor_id);

        -- Create indexes
        CREATE INDEX idx_donations_donor_id ON donations(donor_id);
        CREATE INDEX idx_donations_recipient_id ON donations(recipient_id);
        CREATE INDEX idx_donations_event_id ON donations(event_id);
        CREATE INDEX idx_donations_paypay_payment_id ON donations(paypay_payment_id);

        -- Add trigger
        CREATE TRIGGER update_donations_updated_at BEFORE UPDATE ON donations
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

        RAISE NOTICE 'Created donations table';
    ELSE
        -- Table exists, check and add missing columns
        RAISE NOTICE 'Donations table already exists, checking for missing columns...';
        
        -- Add currency column if it doesn't exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'currency') THEN
            ALTER TABLE donations ADD COLUMN currency VARCHAR(3) DEFAULT 'JPY';
            RAISE NOTICE 'Added currency column';
        END IF;
        
        -- Add paypay_payment_id column if it doesn't exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'paypay_payment_id') THEN
            ALTER TABLE donations ADD COLUMN paypay_payment_id VARCHAR(255) UNIQUE;
            RAISE NOTICE 'Added paypay_payment_id column';
        END IF;
        
        -- Add paypay_merchant_payment_id column if it doesn't exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'paypay_merchant_payment_id') THEN
            ALTER TABLE donations ADD COLUMN paypay_merchant_payment_id VARCHAR(255);
            RAISE NOTICE 'Added paypay_merchant_payment_id column';
        END IF;
        
        -- Add paypay_qr_code_url column if it doesn't exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'paypay_qr_code_url') THEN
            ALTER TABLE donations ADD COLUMN paypay_qr_code_url TEXT;
            RAISE NOTICE 'Added paypay_qr_code_url column';
        END IF;
        
        -- Add message column if it doesn't exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'message') THEN
            ALTER TABLE donations ADD COLUMN message TEXT;
            RAISE NOTICE 'Added message column';
        END IF;
        
        -- Add updated_at column if it doesn't exist
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'updated_at') THEN
            ALTER TABLE donations ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            RAISE NOTICE 'Added updated_at column';
        END IF;
        
        -- Check if event_id is NOT NULL and make it nullable
        IF EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'donations' AND column_name = 'event_id' AND is_nullable = 'NO') THEN
            ALTER TABLE donations ALTER COLUMN event_id DROP NOT NULL;
            RAISE NOTICE 'Made event_id nullable';
        END IF;
        
        -- Enable RLS if not already enabled
        IF NOT EXISTS (SELECT FROM pg_tables WHERE tablename = 'donations' AND rowsecurity = true) THEN
            ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
            RAISE NOTICE 'Enabled RLS';
        END IF;
        
        -- Create policies if they don't exist
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'donations' AND policyname = 'Users can view their own donations') THEN
            CREATE POLICY "Users can view their own donations" ON donations
                FOR SELECT USING (auth.uid() = donor_id OR auth.uid() = recipient_id);
            RAISE NOTICE 'Created view policy';
        END IF;
        
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'donations' AND policyname = 'Users can create donations') THEN
            CREATE POLICY "Users can create donations" ON donations
                FOR INSERT WITH CHECK (auth.uid() = donor_id);
            RAISE NOTICE 'Created insert policy';
        END IF;
        
        IF NOT EXISTS (SELECT FROM pg_policies WHERE tablename = 'donations' AND policyname = 'Users can update their own donations') THEN
            CREATE POLICY "Users can update their own donations" ON donations
                FOR UPDATE USING (auth.uid() = donor_id);
            RAISE NOTICE 'Created update policy';
        END IF;
        
        -- Create indexes if they don't exist
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE tablename = 'donations' AND indexname = 'idx_donations_donor_id') THEN
            CREATE INDEX idx_donations_donor_id ON donations(donor_id);
            RAISE NOTICE 'Created donor_id index';
        END IF;
        
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE tablename = 'donations' AND indexname = 'idx_donations_recipient_id') THEN
            CREATE INDEX idx_donations_recipient_id ON donations(recipient_id);
            RAISE NOTICE 'Created recipient_id index';
        END IF;
        
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE tablename = 'donations' AND indexname = 'idx_donations_event_id') THEN
            CREATE INDEX idx_donations_event_id ON donations(event_id);
            RAISE NOTICE 'Created event_id index';
        END IF;
        
        IF NOT EXISTS (SELECT FROM pg_indexes WHERE tablename = 'donations' AND indexname = 'idx_donations_paypay_payment_id') THEN
            CREATE INDEX idx_donations_paypay_payment_id ON donations(paypay_payment_id);
            RAISE NOTICE 'Created paypay_payment_id index';
        END IF;
        
        -- Create trigger if it doesn't exist
        IF NOT EXISTS (SELECT FROM pg_trigger WHERE tgname = 'update_donations_updated_at') THEN
            CREATE TRIGGER update_donations_updated_at BEFORE UPDATE ON donations
                FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
            RAISE NOTICE 'Created updated_at trigger';
        END IF;
        
        RAISE NOTICE 'Donations table check and fix completed';
    END IF;
END $$; 