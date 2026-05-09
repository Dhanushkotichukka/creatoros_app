const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
  },
  email: {
    type: String,
    required: true,
    unique: true,
  },
  googleId: {
    type: String,
    unique: true,
    sparse: true, // Allows multiple null googleIds
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
    type: Map,
    of: mongoose.Schema.Types.Mixed,
    default: {},
  }
}, {
  timestamps: true,
});

module.exports = mongoose.model('User', userSchema);
