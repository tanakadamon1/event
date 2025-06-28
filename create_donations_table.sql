-- Create donations table for PayPay donations
CREATE TABLE IF NOT EXISTS donations (
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

-- Enable RLS for donations table
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;

-- Donations policies
CREATE POLICY "Users can view their own donations" ON donations
    FOR SELECT USING (auth.uid() = donor_id OR auth.uid() = recipient_id);

CREATE POLICY "Users can create donations" ON donations
    FOR INSERT WITH CHECK (auth.uid() = donor_id);

CREATE POLICY "Users can update their own donations" ON donations
    FOR UPDATE USING (auth.uid() = donor_id);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON donations(donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_recipient_id ON donations(recipient_id);
CREATE INDEX IF NOT EXISTS idx_donations_event_id ON donations(event_id);
CREATE INDEX IF NOT EXISTS idx_donations_paypay_payment_id ON donations(paypay_payment_id);

-- Add trigger for updated_at
CREATE TRIGGER update_donations_updated_at BEFORE UPDATE ON donations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column(); 