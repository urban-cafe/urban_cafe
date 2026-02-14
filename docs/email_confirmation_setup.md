# Email Confirmation Setup Guide

## Overview
This guide shows how to configure Supabase to use the custom email confirmation screen in your Flutter app.

## Step 1: Update Supabase URL Configuration

1. Go to [Supabase Dashboard](https://supabase.com/dashboard/project/sgjanqztqiizffvakusi)
2. Navigate to **Authentication** → **URL Configuration**
3. Update the following settings:

### Site URL
```
https://sgjanqztqiizffvakusi.supabase.co
```

### Redirect URLs (Add all of these)
```
io.supabase.urbancafe://login-callback/
io.supabase.urbancafe://auth/callback/
https://sgjanqztqiizffvakusi.supabase.co/auth/callback
http://localhost:3000/auth/callback
```

4. Click **Save**

## Step 2: Update Email Template (Optional)

The default email template should work, but you can customize it:

1. Go to **Authentication** → **Email Templates**
2. Select **Confirm signup** template
3. The default template uses `{{ .ConfirmationURL }}` which will redirect to your Site URL
4. Click **Save**

## Step 3: Test the Flow

### Testing on Mobile Device/Emulator:
1. Sign up with a new email
2. Check your email inbox
3. Click "Confirm your mail" link
4. You should see the custom success screen in your app
5. Click "Sign In Now" to go to login

### Testing on Web:
1. Sign up with a new email
2. Check your email inbox
3. Click "Confirm your mail" link
4. You'll be redirected to `https://sgjanqztqiizffvakusi.supabase.co/auth/callback`
5. The custom success screen will show
6. Click "Sign In Now" to go to login

## How It Works

### Mobile Deep Link Flow:
```
Email Link → Supabase → io.supabase.urbancafe://auth/callback/ → App Opens → Success Screen
```

### Web Flow:
```
Email Link → Supabase → https://sgjanqztqiizffvakusi.supabase.co/auth/callback → Success Screen
```

## Success Screen Features

✅ **Success State:**
- Green checkmark icon with animation
- "Email Verified!" title
- Success message
- "Sign In Now" button → redirects to login
- "Continue Browsing as Guest" button → redirects to home

❌ **Error State:**
- Red error icon
- "Verification Failed" title
- Error message (e.g., "Link expired")
- "Try Again" button → redirects to login

## Common Issues

### Issue: "This site can't be reached" (localhost:3000)
**Solution**: Update the Site URL in Supabase to use the production URL or deep link scheme.

### Issue: Link expired error
**Solution**: Email verification links expire after 24 hours. Request a new verification email.

### Issue: Deep link doesn't open app
**Solution**: 
- Make sure the app is installed
- Verify `CFBundleURLTypes` is in iOS `Info.plist`
- Verify `intent-filter` is in Android `AndroidManifest.xml`

## Route Details

The email confirmation screen is registered at:
- Route: `/auth/callback`
- Deep Link: `io.supabase.urbancafe://auth/callback/`
- Web URL: `https://sgjanqztqiizffvakusi.supabase.co/auth/callback`

It handles query parameters:
- `error` - Error type (if any)
- `error_code` - Specific error code (e.g., `otp_expired`)
- `error_description` - Human-readable error message
