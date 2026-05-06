require('dotenv').config();
const { Groq } = require('groq-sdk');
const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });

async function test() {
    try {
        const prompt = `Identify 5 highly viral and trending topics in 'Movies' for YouTube.
        Consider this external context if relevant - Google Trends: . News: .
        Return ONLY a JSON array of objects: { "title": string, "trendScore": number (1-10), "difficulty": string, "sources": ["YouTube", "Google Trends", "News"] }. Ensure it's valid JSON.`;

        const completion = await groq.chat.completions.create({
            messages: [{ role: 'user', content: prompt }],
            model: 'llama-3.1-70b-versatile',
            response_format: { type: "json_object" }
        });
        console.log("SUCCESS:", completion.choices[0].message.content);
    } catch (e) {
        console.error("ERROR:", e);
    }
}
test();
