const nodemailer = require('nodemailer');
const dns = require('dns');

// Force IPv4 to prevent IPv6 routing timeouts on Render with Node 18+
dns.setDefaultResultOrder('ipv4first');

// Create reusable transporter
const createTransporter = () => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    throw new Error('[EMAIL] EMAIL_USER or EMAIL_PASS not set in .env');
  }
  return nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // true for 465
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
    connectionTimeout: 15000, // 15 seconds
    greetingTimeout: 15000,
    socketTimeout: 15000,
  });
};

/**
 * Send email verification OTP
 */
const sendVerificationOTP = async (email, name, otp) => {
  const transporter = createTransporter();

  const mailOptions = {
    from: `"CreatorOS 🚀" <creatoros.app.connect@gmail.com>`,
    to: email,
    subject: 'Verify your CreatorOS account',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; background: #0d0d0d; color: #ffffff; border-radius: 16px; overflow: hidden;">
        <div style="background: linear-gradient(135deg, #FF6B00, #FF8C42); padding: 32px; text-align: center;">
          <h1 style="margin: 0; font-size: 28px; font-weight: 900; letter-spacing: -1px;">CreatorOS</h1>
          <p style="margin: 8px 0 0; opacity: 0.9;">The Ultimate Hub for Modern Creators</p>
        </div>
        <div style="padding: 32px;">
          <h2 style="color: #FF6B00; margin-top: 0;">Hi ${name}! 👋</h2>
          <p style="color: #aaa; line-height: 1.6;">Welcome to CreatorOS! Use the OTP below to verify your email address. This code expires in <strong style="color: #fff;">10 minutes</strong>.</p>
          <div style="background: #1a1a1a; border: 2px solid #FF6B00; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
            <p style="color: #aaa; font-size: 14px; margin: 0 0 8px;">Your verification code</p>
            <h1 style="color: #FF6B00; font-size: 48px; letter-spacing: 12px; margin: 0;">${otp}</h1>
          </div>
          <p style="color: #666; font-size: 13px;">If you didn't create a CreatorOS account, you can safely ignore this email.</p>
        </div>
      </div>
    `,
  };

  const info = await transporter.sendMail(mailOptions);
  console.log(`[EMAIL] ✅ Verification OTP sent to ${email} — MessageId: ${info.messageId}`);
};

/**
 * Send password reset OTP
 */
const sendPasswordResetOTP = async (email, name, otp) => {
  const transporter = createTransporter();

  const mailOptions = {
    from: `"CreatorOS 🚀" <creatoros.app.connect@gmail.com>`,
    to: email,
    subject: 'Reset your CreatorOS password',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; background: #0d0d0d; color: #ffffff; border-radius: 16px; overflow: hidden;">
        <div style="background: linear-gradient(135deg, #FF6B00, #FF8C42); padding: 32px; text-align: center;">
          <h1 style="margin: 0; font-size: 28px; font-weight: 900; letter-spacing: -1px;">CreatorOS</h1>
          <p style="margin: 8px 0 0; opacity: 0.9;">Password Reset</p>
        </div>
        <div style="padding: 32px;">
          <h2 style="color: #FF6B00; margin-top: 0;">Reset Password</h2>
          <p style="color: #aaa; line-height: 1.6;">Hi ${name}, we received a request to reset your password. Use the code below. Expires in <strong style="color: #fff;">10 minutes</strong>.</p>
          <div style="background: #1a1a1a; border: 2px solid #FF6B00; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
            <p style="color: #aaa; font-size: 14px; margin: 0 0 8px;">Your reset code</p>
            <h1 style="color: #FF6B00; font-size: 48px; letter-spacing: 12px; margin: 0;">${otp}</h1>
          </div>
          <p style="color: #666; font-size: 13px;">If you didn't request this, your account is safe. No changes were made.</p>
        </div>
      </div>
    `,
  };

  const info = await transporter.sendMail(mailOptions);
  console.log(`[EMAIL] ✅ Password reset OTP sent to ${email} — MessageId: ${info.messageId}`);
};

module.exports = { sendVerificationOTP, sendPasswordResetOTP };
