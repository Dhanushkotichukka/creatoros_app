const { GoogleGenerativeAI } = require("@google/generative-ai");
require('dotenv').config();

async function listModels() {
    try {
        const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
        // There isn't a direct 'listModels' in the simple SDK usually, 
        // but we can try to hit the endpoint or just try a few more variants.
        console.log("Testing Gemini API Key...");
        
        const modelsToTest = [
            "gemini-1.5-flash",
            "gemini-1.5-flash-latest",
            "gemini-1.5-pro",
            "gemini-pro",
            "gemini-2.0-flash-exp"
        ];

        for (const modelName of modelsToTest) {
            try {
                const model = genAI.getGenerativeModel({ model: modelName });
                const result = await model.generateContent("Hello, are you active?");
                const response = await result.response;
                console.log(`✅ Model ${modelName} is working!`);
                return; // Stop if one works
            } catch (e) {
                console.log(`❌ Model ${modelName} failed: ${e.message}`);
            }
        }
    } catch (err) {
        console.error("General error:", err.message);
    }
}

listModels();
