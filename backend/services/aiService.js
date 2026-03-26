const { Groq } = require('groq-sdk');
const { GoogleGenerativeAI } = require('@google/generative-ai');
require('dotenv').config();

const groq = new Groq({
    apiKey: process.env.GROQ_API_KEY,
});

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

exports.generateScript = async (topic) => {
    try {
        const chatCompletion = await groq.chat.completions.create({
            messages: [
                {
                    role: 'system',
                    content: 'You are an elite YouTube strategist and content creator assistant.',
                },
                {
                    role: 'user',
                    content: `Generate a high-retention short video script (30-60 seconds) for a content creator. Topic/context: ${topic}. Structure it strictly with: 1) A hook in the first 3 seconds, 2) Introduction, 3) Main value body, 4) A compelling CTA.`,
                },
            ],
            model: 'llama3-8b-8192',
        });

        return chatCompletion.choices[0].message.content;
    } catch (error) {
        console.error('Error with Groq:', error);
        // Fallback to Gemini if Groq fails
        return this.generateWithGemini(topic);
    }
};

exports.generateWithGemini = async (topic) => {
    try {
        const model = genAI.getGenerativeModel({ model: 'gemini-pro' });
        const result = await model.generateContent(`Generate a YouTube script about: ${topic}`);
        const response = await result.response;
        return response.text();
    } catch (error) {
        console.error('Error with Gemini:', error);
        throw new Error('AI generation failed');
    }
};

exports.generateHashtags = async (topic) => {
    try {
        const chatCompletion = await groq.chat.completions.create({
            messages: [
                {
                    role: 'system',
                    content: 'You are an expert social media manager.',
                },
                {
                    role: 'user',
                    content: `Generate 10-15 relevant and trending hashtags for: ${topic}. Mix highly popular and niche tags. Return only the hashtags separated by spaces.`,
                },
            ],
            model: 'llama3-8b-8192',
        });

        return chatCompletion.choices[0].message.content;
    } catch (error) {
        console.error('Error with Groq hashtags:', error);
        return '#ai #contentcreator #productivity #viral #trends'; // Fallback
    }
};

exports.generateHooks = async (topic) => {
    try {
        const chatCompletion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: `Generate 3 attention-grabbing video hooks (first 3-5 seconds) for: ${topic}. Each should be punchy, highly engaging, and curiosity-driven. Return as a numbered list.` }],
            model: 'llama3-8b-8192',
        });
        return chatCompletion.choices[0].message.content;
    } catch (error) {
        console.error('Hooks error:', error);
        return '1. Want to know a secret about ' + topic + '?\n2. Stop scrolling if you care about ' + topic + '\n3. The truth about ' + topic;
    }
};

exports.generateCaption = async (topic) => {
    try {
        const chatCompletion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: `Write an engaging social media caption (1-3 sentences) for: ${topic}. Include a call-to-action.` }],
            model: 'llama3-8b-8192',
        });
        return chatCompletion.choices[0].message.content;
    } catch (error) {
        console.error('Caption error:', error);
        return 'Check out this new update about ' + topic + '! What do you think? Let me know below! 👇';
    }
};
