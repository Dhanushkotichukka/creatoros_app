const mongoose = require('mongoose');
const { v4: uuidv4 } = require('uuid');

const userSchema = new mongoose.Schema({
  _id: {
    type: String,
    default: uuidv4
  },
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
    sparse: true,
    lowercase: true,
    trim: true,
  },
  password: {
    type: String, // bcrypt hashed — null for Google-only users
    default: null,
  },
  authProvider: {
    type: String,
    enum: ['google', 'email'],
    default: 'google',
  },
  isVerified: {
    type: Boolean,
    default: false, // true immediately for Google users
  },
  googleId: {
    type: String,
    unique: true,
    sparse: true,
  },
  profilePicture: {
    type: String,
  },
  phone: {
    type: String,
  },
  bio: {
    type: String,
  },
  creatorScore: {
    type: Number,
    default: 0,
  },
  preferences: {
    type: Object,
    default: {},
  }
}, {
  timestamps: true,
});

const User = mongoose.model('User', userSchema);
module.exports = User;
