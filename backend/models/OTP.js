const mongoose = require('mongoose');

const otpSchema = new mongoose.Schema({
  userId: {
    type: String,
    required: true,
    index: true,
  },
  email: {
    type: String,
    required: true,
  },
  otp: {
    type: String,
    required: true,
  },
  type: {
    type: String,
    enum: ['verify_email', 'reset_password'],
    required: true,
  },
  expiresAt: {
    type: Date,
    required: true,
    index: { expires: 0 }, // MongoDB TTL — auto-delete after expiresAt
  },
}, {
  timestamps: true,
});

const OTP = mongoose.model('OTP', otpSchema);
module.exports = OTP;
