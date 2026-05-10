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
    sparse: true, // Allows multiple null googleIds
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
