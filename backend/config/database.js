const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/creatoros';
        await mongoose.connect(uri);
        console.log('MongoDB connected successfully.');
    } catch (error) {
        console.error('Unable to connect to MongoDB:', error.message);
        process.exit(1);
    }
};

module.exports = connectDB;
