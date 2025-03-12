# Plaid OAuth Implementation Guide

This document outlines the steps required to fully implement Plaid OAuth in our mobile application.

## 1. Setup Requirements

### Backend Configuration
- Update our backend API to pass OAuth-specific parameters when creating Link tokens
- Make sure our backend includes `redirect_uri` or `android_package_name` in the request to Plaid

### Environment Configuration
- Add the redirect URI to the allowed redirect URIs in the Plaid Dashboard
- For Android, add the package name to the allowed Android package names list

## 2. Platform-Specific Implementation

### iOS Implementation
1. **Universal Links Configuration**
   - Create an Apple App Site Association file on your server
   - Host it at `https://blink-app.com/.well-known/apple-app-site-association`
   - Configure the app's Associated Domains entitlement with `applinks:blink-app.com`

2. **Handle Deep Links**
   - Install the `uni_links` package for deep link handling
   - Set up a handler in your app to intercept universal links
   - Extract the `oauth_state_id` parameter from the URL

3. **Update Info.plist**
   - Add required entitlements for universal links

### Android Implementation
1. **App Links Configuration**
   - Create an `assetlinks.json` file
   - Host it at `https://blink-app.com/.well-known/assetlinks.json`
   - Update the `package_name` and `sha256_cert_fingerprints` in the file

2. **AndroidManifest.xml Configuration**
   - Add the Intent Filter for handling App Links
   - Make sure `autoVerify="true"` is set
   - Configure the data scheme, host, and path to match your redirect URI

3. **Handle Deep Links**
   - Set up a receiver to handle incoming intents in your MainActivity
   - Extract the `oauth_state_id` parameter from the URL

## 3. Testing OAuth Implementation

### Sandbox Testing
- Test OAuth flows with the Platypus OAuth Bank (institution ID: ins_127287)
- For Europe, use Flexible Platypus Open Banking (institution ID: ins_117181)
- Test the flow on both iOS and Android devices

### App-to-App Testing
- Use First Platypus Bank (institution ID: ins_132241) to test App-to-App authentication
- Test with and without the bank app installed

### Edge Cases to Test
- Test when returning from OAuth with an expired session
- Test error handling and recovery paths
- Test the flow in update mode

## 4. Handling OAuth Events

Make sure to implement proper handling for these OAuth events:
- `OPEN_OAUTH`: Triggered when a user is redirected to the institution's OAuth portal
- `CLOSE_OAUTH`: Triggered when a user closes the OAuth window without completing the flow
- `FAIL_OAUTH`: Triggered when an OAuth flow times out

## 5. Consent Refresh and Revocation

- Implement handling of the `PENDING_EXPIRATION` webhook for UK/EU institutions and Capital One
- For US/CA institutions, implement handling of the `PENDING_DISCONNECT` webhook
- Check the `consent_expiration_time` from `/item/get` endpoint to anticipate when users need to re-authenticate
- Handle cases where users revoke consent via their bank's portal

## 6. Package Versions

Make sure you're using the following package versions:
- Plaid Flutter SDK: Latest version
- uni_links: Latest version for deep linking

## 7. Troubleshooting Common Issues

- Check that deep link handling is properly configured
- Verify redirect URI is correctly registered in Plaid Dashboard
- Make sure your redirect URI uses HTTPS and no hash routing
- For Android, validate the package name matches exactly what's registered
- For iOS, ensure universal links are properly configured

---

Remember to check Plaid's [OAuth documentation](https://plaid.com/docs/link/oauth/) for any updates and additional requirements. 