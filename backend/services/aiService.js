/**
 * ╔══════════════════════════════════════════════════════════════╗
 * ║          CREATORS APP — AI SERVICE (STARTUP EDITION)        ║
 * ║                                                              ║
 * ║  FIX 1: Data Feedback Loop  — store & reuse past results    ║
 * ║  FIX 2: Personalization     — creator memory per channel    ║
 * ║  FIX 3: Model Optimization  — cheap vs powerful routing     ║
 * ║  FIX 4: Sticky Features     — hook rewriter, viral predict  ║
 * ║  FIX 5: Fix My Last Video   — diagnose + rewrite any video  ║
 * ╚══════════════════════════════════════════════════════════════╝
 */

const Groq = require('groq-sdk');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
const genAI = process.env.GEMINI_API_KEY ? new GoogleGenerativeAI(process.env.GEMINI_API_KEY) : null;

// ─── MODEL ROUTING (FIX 3) ───────────────────────────────────────────────────
// Route tasks to the right model by cost vs quality tradeoff.
// Don't burn the big model on simple tasks.
const MODELS = {
    FAST: 'llama-3.1-8b-instant',    // captions, chat, simple rewrites
    SMART: 'llama-3.3-70b-versatile', // analytics, viral prediction, diagnosis
    CREATIVE: 'llama-3.1-8b-instant',   // scripts, hooks, creative writing
};

// ─── CREATOR MEMORY STORE (FIX 2) ────────────────────────────────────────────
// In production, replace with DB (Postgres / Redis / Firestore).
// This in-memory store persists per server instance.
const creatorMemoryStore = new Map();

/**
 * Load a creator's memory profile.
 * Returns: niche, style, past hook types that worked, audience age, best time, etc.
 */
function loadCreatorMemory(channelId) {
    return creatorMemoryStore.get(channelId) || {
        channelId,
        niche: null,
        contentStyle: null,               // 'educational' | 'entertainment' | 'vlog' | 'review'
        audienceAge: null,
        bestPostTime: null,
        winningHookType: null,
        avgRetention: null,
        pastInsightSummaries: [],         // last 5 narrative summaries stored
        pastVideoPerformance: [],         // { title, retention, hookType, postedAt }
        improvementAreas: [],             // recurring weak points flagged by AI
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
    };
}

/**
 * Save updated creator memory back to store.
 */
function saveCreatorMemory(channelId, updates) {
    const existing = loadCreatorMemory(channelId);
    creatorMemoryStore.set(channelId, {
        ...existing,
        ...updates,
        updatedAt: new Date().toISOString(),
    });
}

/**
 * After analytics runs, update creator memory with what we learned.
 * This is the FEEDBACK LOOP (FIX 1 + FIX 2).
 */
function updateCreatorMemoryFromAnalytics(channelId, summary, narrative) {
    const m = summary.metrics || {};
    const existing = loadCreatorMemory(channelId);

    // Keep last 5 insight summaries for context
    const pastInsightSummaries = [
        ...(existing.pastInsightSummaries || []).slice(-4),
        {
            date: new Date().toISOString(),
            winningPattern: narrative.winning_pattern?.title,
            topRetention: m.top_videos_avg_retention,
            hookScore: m.hook_score,
            actionItems: narrative.summary,
        }
    ];

    // Accumulate improvement areas to spot recurring problems
    const improvementAreas = [
        ...(existing.improvementAreas || []).slice(-9),
        ...(narrative.avoid || [])
    ];

    saveCreatorMemory(channelId, {
        niche: summary.niche || existing.niche,
        contentStyle: summary.formatWinner || existing.contentStyle,
        audienceAge: summary.topAgeGroup || existing.audienceAge,
        bestPostTime: summary.bestTime || existing.bestPostTime,
        winningHookType: m.dominant_hook_type || existing.winningHookType,
        avgRetention: m.top_videos_avg_retention || existing.avgRetention,
        pastInsightSummaries,
        improvementAreas,
    });
}

// ─── FEEDBACK LOOP STORE (FIX 1) ─────────────────────────────────────────────
// Track: AI gave suggestion → video was uploaded → real result came in.
const feedbackStore = new Map();

/**
 * Record a new AI suggestion so we can compare against real results later.
 */
function recordSuggestion(channelId, suggestionId, suggestionData) {
    const channelFeedback = feedbackStore.get(channelId) || [];
    channelFeedback.push({
        suggestionId,
        channelId,
        suggestion: suggestionData,
        predictedOutcome: suggestionData.expected_outcome,
        actualRetention: null,      // filled in later via recordActualResult()
        actualViews: null,
        wasHelpful: null,
        recordedAt: new Date().toISOString(),
        resolvedAt: null,
    });
    feedbackStore.set(channelId, channelFeedback.slice(-20)); // keep last 20
}

/**
 * Record the actual outcome after a video goes live.
 * Call this from your video performance webhook / analytics sync.
 */
function recordActualResult(channelId, suggestionId, { actualRetention, actualViews, wasHelpful }) {
    const channelFeedback = feedbackStore.get(channelId) || [];
    const idx = channelFeedback.findIndex(f => f.suggestionId === suggestionId);
    if (idx !== -1) {
        channelFeedback[idx] = {
            ...channelFeedback[idx],
            actualRetention,
            actualViews,
            wasHelpful,
            resolvedAt: new Date().toISOString(),
        };
        feedbackStore.set(channelId, channelFeedback);
    }
}

/**
 * Build a feedback context string to inject into prompts.
 * This closes the loop: AI sees what worked and what didn't.
 */
function buildFeedbackContext(channelId) {
    const channelFeedback = feedbackStore.get(channelId) || [];
    const resolved = channelFeedback.filter(f => f.actualRetention !== null);
    if (!resolved.length) return '';

    const lines = resolved.slice(-5).map(f =>
        `• Suggested: "${f.suggestion?.content_idea || 'hook rewrite'}" → Predicted: ${f.predictedOutcome} → Actual retention: ${f.actualRetention}%`
    );
    return `\nPAST SUGGESTION ACCURACY (use to calibrate predictions):\n${lines.join('\n')}\n`;
}

// ─── HELPER: Build personalization context string ─────────────────────────────
function buildPersonalizationContext(channelId) {
    const mem = loadCreatorMemory(channelId);
    if (!mem.niche && !mem.winningHookType) return '';

    const parts = [];
    if (mem.niche) parts.push(`Niche: ${mem.niche}`);
    if (mem.contentStyle) parts.push(`Content style: ${mem.contentStyle}`);
    if (mem.winningHookType) parts.push(`Winning hook type historically: ${mem.winningHookType}`);
    if (mem.avgRetention) parts.push(`Channel avg retention (historical): ${mem.avgRetention}%`);
    if (mem.audienceAge) parts.push(`Primary audience age: ${mem.audienceAge}`);
    if (mem.bestPostTime) parts.push(`Best post time: ${mem.bestPostTime}`);

    const recurringWeaknesses = [...new Set(mem.improvementAreas)].slice(0, 3);
    if (recurringWeaknesses.length) {
        parts.push(`Recurring weaknesses to address: ${recurringWeaknesses.join('; ')}`);
    }

    if (mem.pastInsightSummaries?.length) {
        const last = mem.pastInsightSummaries[mem.pastInsightSummaries.length - 1];
        parts.push(`Last analysis (${last.date?.split('T')[0]}): ${last.winningPattern}, top retention ${last.topRetention}%`);
    }

    return parts.length ? `\nCREATOR PROFILE (learned over time):\n${parts.join('\n')}\n` : '';
}

// ─── SCRIPT OUTLINE ──────────────────────────────────────────────────────────

exports.generateScriptOutline = async (topic, channelId = null) => {
    const personalContext = channelId ? buildPersonalizationContext(channelId) : '';
    try {
        const completion = await groq.chat.completions.create({
            messages: [{
                role: 'system',
                content: `You are a professional YouTube scriptwriter who has written for channels with 1M+ subscribers. You understand pacing, retention psychology, and the YouTube algorithm. Always write in a direct, actionable tone — no fluff.${personalContext}`
            }, {
                role: 'user',
                content: `Write a high-retention YouTube script outline for: "${topic}"

Return a structured outline with these exact sections:

HOOK (0–15 sec)
- Opening line (verbatim — the exact first words to say)
- Pattern interrupt technique used (curiosity gap / shocking stat / bold claim / story)
- Promise made to viewer

INTRO (15–60 sec)
- Why this matters to the viewer (not to you)
- Credibility signal
- What they'll leave knowing

MAIN CONTENT (3 sections, 2–4 min each)
For each section:
- Heading + viewer benefit
- Key point or argument
- Supporting example or data
- Transition line to next section

RETENTION MOMENT (mid-video)
- Pattern interrupt or re-hook line to prevent drop-off at the 40–50% mark

CTA (final 30 sec)
- Specific ask (subscribe, comment prompt, next video)
- Exit line that leaves them wanting more

THUMBNAIL ANGLE
- Visual concept that creates a curiosity gap without being clickbait`
            }],
            model: MODELS.CREATIVE,
            temperature: 0.65,
            max_tokens: 1000,
        });
        return completion.choices[0].message.content;
    } catch (error) {
        console.error('[ScriptOutline] Error:', error);
        return `Script outline for "${topic}":\n1. Hook: Start with a bold claim\n2. Intro: Explain the viewer benefit\n3. Main points: Cover key aspects with examples\n4. CTA: Subscribe + comment prompt`;
    }
};

// ─── AI CHAT ASSISTANT ────────────────────────────────────────────────────────

exports.generateAIChat = async (message, context = '', channelId = null) => {
    const personalContext = channelId ? buildPersonalizationContext(channelId) : '';
    const feedbackCtx = channelId ? buildFeedbackContext(channelId) : '';

    const systemPrompt = `You are an elite YouTube growth strategist with deep expertise in retention psychology, the YouTube algorithm, hook writing, thumbnail strategy, and channel monetization. You are direct and specific — never vague. Every answer is tied to data or proven creator psychology.
${context ? `\nSession context: ${context}` : ''}${personalContext}${feedbackCtx}
When answering, prioritize insights specific to this creator's history over generic YouTube advice.`;

    try {
        const completion = await groq.chat.completions.create({
            messages: [
                { role: 'system', content: systemPrompt },
                { role: 'user', content: message }
            ],
            model: MODELS.FAST,
            temperature: 0.6,
            max_tokens: 500,
        });
        return completion.choices[0].message.content;
    } catch (error) {
        console.error('[AIChat] Error:', error);
        return 'Unable to process your request right now. Please try again in a moment.';
    }
};

// ─── TREND ANALYSIS ───────────────────────────────────────────────────────────

exports.generateTrendAnalysis = async (topics, channelId = null) => {
    const personalContext = channelId ? buildPersonalizationContext(channelId) : '';
    try {
        const completion = await groq.chat.completions.create({
            messages: [{
                role: 'system',
                content: `You are a YouTube trend analyst. Your job is to evaluate topics for content opportunity — not just whether they are popular, but whether a mid-sized creator (10k–500k subs) can realistically compete and grow from them right now.${personalContext}`
            }, {
                role: 'user',
                content: `Analyze these topics for YouTube content opportunity: ${topics.join(', ')}

For EACH topic, output:

TOPIC: [name]
Trend momentum: [Rising / Peaked / Declining] — [one sentence why]
Audience intent: [What is the viewer actually searching for / hoping to get?]
Competition difficulty: [Low / Medium / High] — [why]
Content opportunity: [The specific angle a creator should take — not the generic version, the differentiated one]
Video idea: [Exact title using proven format: Question / Stat / Controversy / How-to]
Best hook type: [Question / Shocking stat / Contrarian claim / Story]
Estimated retention potential: [Low / Medium / High] — [based on topic engagement patterns]

Avoid generic analysis. Be specific about what will actually perform.`
            }],
            model: MODELS.FAST,
            temperature: 0.45,
            max_tokens: 800,
        });
        return completion.choices[0].message.content;
    } catch (error) {
        console.error('[TrendAnalysis] Error:', error);
        return 'Trend analysis temporarily unavailable. Please try again.';
    }
};

// ─── ANALYTICS NARRATIVE — ELITE PATTERN ENGINE ───────────────────────────────

exports.analyzeChannelData = async (summary, channelId = null) => {
    const m = summary.metrics || {};
    const hasRealData = (summary.top_videos || []).some(v => v.avg_view_percentage > 0);

    const topV = (summary.top_videos || []).slice(0, 5)
        .map(v => `• "${v.title}" — ${v.avg_view_percentage}% retention, ${v.avg_view_duration}s avg, ${v.hookType} hook, ${v.views} views`)
        .join('\n') || 'Insufficient data';

    const lowV = (summary.low_videos || []).slice(0, 5)
        .map(v => `• "${v.title}" — ${v.avg_view_percentage}% retention, ${v.avg_view_duration}s avg, ${v.hookType} hook, ${v.views} views`)
        .join('\n') || 'Insufficient data';

    const hookRetStr = Object.entries(m.hook_retention_by_type || {})
        .sort(([, a], [, b]) => b - a)
        .map(([type, ret]) => `${type}: ${ret}%`)
        .join(' | ') || 'No hook data';

    const perfGap = m.performance_gap_ratio && m.performance_gap_ratio !== 'N/A'
        ? `${m.performance_gap_ratio}x` : 'N/A';

    const topEx = summary.top_videos?.[0] || {};
    const lowEx = summary.low_videos?.[0] || {};

    // Personalization + feedback context (FIX 1 + FIX 2)
    const personalContext = channelId ? buildPersonalizationContext(channelId) : '';
    const feedbackCtx = channelId ? buildFeedbackContext(channelId) : '';

    const fallback = buildFallback(summary, m, topEx, lowEx, perfGap, hasRealData);

    const systemPrompt = `You are an elite YouTube Channel Intelligence System. You do not give generic advice. You extract cross-video patterns from real data, quantify performance gaps, identify root causes, and produce exact execution plans.
${personalContext}${feedbackCtx}
═══════════════════════════════════
ANALYSIS RULES (follow strictly)
═══════════════════════════════════
1. ISOLATE LOGIC: Strategy must ONLY discuss content format/patterns. Timing must ONLY discuss posting hours. Summary must ONLY be a 3-step action checklist. Do NOT repeat yourself across these.
2. WINNING PATTERN: Must be highly specific. Include duration_range, hook_type, and exact multiplier (e.g., "2.3x better").
3. PERFORMANCE GAP: Must clearly list what 'top_videos_use' vs 'low_videos_use' and provide a clear 'action_to_take'.
4. NEXT VIDEO TIMELINE: 'next_video_plan' MUST include a 3-step 'structure' array breaking down the script by seconds (e.g., Hook 0-3s).
5. AVOID SECTION: List exactly 2-3 specific things to STOP doing based on low performers.
6. SCORES/MISSING DATA: If retention is 0%, DATA IS UNAVAILABLE. Do NOT fabricate patterns about 0% retention. Explicitly state "Data Unavailable".

Return ONLY this JSON schema:
{
  "winning_pattern": { "title": "...", "insight": "...", "why_it_works": "...", "duration_range": "...", "hook_type": "...", "multiplier": "..." },
  "hook_analysis": { "quality": "strong|average|poor", "insight": "...", "weakness_reason": "...", "comparison": "...", "retention_by_type": {} },
  "scores": { "hook_score": null, "retention_score": null, "growth_score": null, "note": "..." },
  "performance_gap": { "top_avg": 0, "low_avg": 0, "gap_ratio": "Nx", "explanation": "...", "top_videos_use": ["...", "..."], "low_videos_use": ["...", "..."], "action_to_take": "..." },
  "top_vs_low_analysis": { "top_performer_example": "...", "low_performer_example": "...", "key_difference": "..." },
  "action_plan": { "summary": "...", "steps": ["...", "...", "..."] },
  "avoid": ["...", "...", "..."],
  "next_video_plan": { "hook": "exact opening sentence", "format": "...", "length": "...", "posting_time": "...", "content_idea": "...", "expected_outcome": "...", "structure": [{"step": "...", "detail": "..."}, {"step": "...", "detail": "..."}] },
  "content_ideas": ["...", "...", "..."],
  "confidence": { "score": 0, "reason": "..." },
  "performance": { "problem": "...", "why": "...", "action": "..." },
  "hooks": { "problem": "...", "why": "...", "action": "..." },
  "strategy": { "problem": "...", "why": "...", "action": "..." },
  "timing": { "problem": "...", "why": "...", "action": "..." },
  "alerts": { "problem": "...", "why": "...", "action": "..." },
  "summary": ["...", "...", "..."]
}`;

    const userPrompt = `═══════════════════════════════════
CHANNEL BRIEF
═══════════════════════════════════
Channel: ${summary.channel_name || 'Unknown'}
Status: ${summary.performanceStatus}
Primary audience: Age ${summary.topAgeGroup}, optimal post time: ${summary.bestTime}
Best-performing format: ${summary.formatWinner}
Upload consistency: ${summary.consistencyStatus}

HOOK INTELLIGENCE:
- Overall hook quality: ${summary.hookSummary?.hook_quality || 'unknown'}
- Channel avg retention: ${summary.hookSummary?.avg_view_percentage || 0}%
- Videos with weak hooks (<30% retention): ${summary.hookSummary?.weak_hook_ratio || 0}%
- Retention ranked by hook type: ${hookRetStr}

PERFORMANCE GAP:
- Top 5 avg retention: ${m.top_videos_avg_retention || 0}%
- Bottom 5 avg retention: ${m.low_videos_avg_retention || 0}%
- Gap multiplier: ${perfGap}
- Total videos analyzed: ${m.videos_analyzed || 0}

TOP 5 PERFORMERS:
${topV}

BOTTOM 5 PERFORMERS:
${lowV}

CHANNEL SCORES (null = data unavailable — do NOT fabricate):
- Hook Score: ${m.hook_score != null ? m.hook_score + '/100' : 'null'}
- Retention Score: ${m.retention_score != null ? m.retention_score + '/100' : 'null'}
- Growth Score: ${m.growth_score != null ? m.growth_score + '/100' : 'null'}`;

    try {
        const rawParsed = await executeWithFailover({
            system: systemPrompt,
            user: userPrompt,
            primaryEngine: 'groq',
            model: MODELS.SMART,
            timeout: 15000,
            isJson: true
        });

        const result = mergeWithFallback(rawParsed, fallback);

        // FIX 1+2: Update memory and store suggestion for feedback loop
        if (channelId) {
            updateCreatorMemoryFromAnalytics(channelId, summary, result);
            recordSuggestion(channelId, `analytics_${Date.now()}`, result.next_video_plan);
        }

        return result;
    } catch (err) {
        console.warn('[AnalyticsNarrative] Failed, using fallback:', err.message);
        return fallback;
    }
};

// ─── CAPTION GENERATOR ───────────────────────────────────────────────────────

exports.generateCaption = async (topic, channelId = null) => {
    const personalContext = channelId ? buildPersonalizationContext(channelId) : '';
    try {
        const completion = await groq.chat.completions.create({
            messages: [{
                role: 'system',
                content: `You write high-converting social media captions. Your captions create curiosity, deliver value fast, and end with a CTA that feels natural — not forced.${personalContext}`
            }, {
                role: 'user',
                content: `Write 3 caption variations for: "${topic}"

Variation 1 — CURIOSITY HOOK: Opens with an unexpected question or contrarian take. 2–3 sentences. Ends with a soft CTA.
Variation 2 — VALUE LEAD: Opens with the most useful insight immediately. 2–3 sentences. Ends with engagement CTA.
Variation 3 — STORY HOOK: Opens with a micro-story or personal moment. 2–3 sentences. Ends with a relatable CTA.

Each caption opening line must be under 150 characters. Label each variation clearly.`
            }],
            model: MODELS.FAST,
            temperature: 0.75,
            max_tokens: 400,
        });
        return completion.choices[0].message.content;
    } catch (error) {
        console.error('[Caption] Error:', error);
        return `Check out this update on ${topic}. What do you think — let me know below!`;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// ─── STICKY FEATURE 1: HOOK REWRITER (FIX 4) ─────────────────────────────────
// The #1 daily-use feature. Creator pastes their hook → gets 5 rewritten versions
// ranked by predicted retention impact, with psychological reasoning.
// ═══════════════════════════════════════════════════════════════════════════════

exports.rewriteHook = async (originalHook, videoTopic, channelId = null) => {
    const mem = channelId ? loadCreatorMemory(channelId) : {};
    const winningType = mem.winningHookType || 'Question';

    try {
        const completion = await groq.chat.completions.create({
            messages: [{
                role: 'system',
                content: `You are the world's best YouTube hook writer. You have studied the opening seconds of 10,000+ videos and know exactly what makes viewers stay or leave. You write hooks that create an irresistible information gap in the first 10 words.`
            }, {
                role: 'user',
                content: `Rewrite this YouTube hook to maximize viewer retention.

ORIGINAL HOOK: "${originalHook}"
VIDEO TOPIC: "${videoTopic}"
${winningType ? `CREATOR'S HISTORICALLY BEST HOOK TYPE: ${winningType} (prioritize this style)` : ''}

Write 5 rewritten hook versions. For EACH:

VERSION [N] — [Hook Type: Question / Shock / Contrarian / Story / Pattern Interrupt]
Hook: [Exact words to say — under 25 words]
Why it works: [Psychological trigger in 1 sentence]
Predicted retention vs original: [+X% estimate]
Best for: [Thumbnail style this pairs with]

Rank them 1–5 with #1 being strongest predicted performer.

Rules:
- Never start with "In this video" or "Today I will"
- Never state the topic directly — create a GAP first
- The first 8 words must force the viewer to want the next sentence
- Each version must use a DIFFERENT psychological trigger`
            }],
            model: MODELS.SMART,
            temperature: 0.7,
            max_tokens: 900,
        });
        return completion.choices[0].message.content;
    } catch (error) {
        console.error('[HookRewriter] Error:', error);
        return `Could not rewrite hook. Try again — or rephrase your original as a question starting with "Why" or "What nobody tells you about..."`;
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// ─── STICKY FEATURE 2: VIRAL PREDICTOR (FIX 4) ───────────────────────────────
// Creator inputs their video idea + hook → AI predicts viral potential score,
// explains what's working and what will kill it, gives exact fix.
// Uses the SMART model because this is high-stakes advice.
// ═══════════════════════════════════════════════════════════════════════════════

exports.predictViralPotential = async ({ title, hook, description, channelId = null }) => {
    const mem = channelId ? loadCreatorMemory(channelId) : {};
    const feedbackCtx = channelId ? buildFeedbackContext(channelId) : '';

    try {
        const completion = await groq.chat.completions.create({
            messages: [{
                role: 'system',
                content: `You are a YouTube algorithm expert who has reverse-engineered viral video patterns across 50,000+ videos. You predict viral potential based on: hook strength, title curiosity gap, search intent match, thumbnail compatibility, retention probability, and algorithmic shareability signals.`
            }, {
                role: 'user',
                content: `Predict the viral potential of this video idea:

TITLE: "${title}"
HOOK (first words): "${hook || 'Not provided'}"
DESCRIPTION/IDEA: "${description || 'Not provided'}"
${mem.niche ? `CHANNEL NICHE: ${mem.niche}` : ''}
${mem.avgRetention ? `CHANNEL AVG RETENTION: ${mem.avgRetention}%` : ''}
${feedbackCtx}

Analyze and return ONLY valid JSON:
{
  "viral_score": 0-100,
  "verdict": "Low potential | Growing potential | High potential | Viral candidate",
  "title_analysis": {
    "score": 0-100,
    "curiosity_gap": "strong|weak|none",
    "search_intent": "matches|partial|misses",
    "issue": "specific problem if score < 70",
    "fix": "exact rewritten title"
  },
  "hook_analysis": {
    "score": 0-100,
    "type": "Question|Shock|Story|Contrarian|Weak",
    "issue": "specific problem if score < 70",
    "fix": "exact rewritten hook (under 20 words)"
  },
  "retention_prediction": {
    "estimated_avg_retention": "X%",
    "drop_off_risk": "Low|Medium|High",
    "risk_reason": "specific reason"
  },
  "algorithmic_signals": {
    "ctr_prediction": "Low|Medium|High",
    "shareability": "Low|Medium|High",
    "searchability": "Low|Medium|High"
  },
  "what_will_kill_it": ["specific killer 1", "specific killer 2"],
  "what_will_save_it": ["specific fix 1", "specific fix 2"],
  "thumbnail_concept": "exact visual concept that pairs with this title to maximize CTR",
  "verdict_reason": "2-sentence honest assessment"
}`
            }],
            model: MODELS.SMART,
            temperature: 0.3,
            max_tokens: 800,
        });

        const raw = completion.choices[0].message.content.trim();
        const jsonMatch = raw.match(/\{[\s\S]*\}/);
        if (!jsonMatch) throw new Error('No JSON in viral prediction response');

        const result = JSON.parse(jsonMatch[0]);

        // Record suggestion for feedback loop
        if (channelId) {
            recordSuggestion(channelId, `viral_${Date.now()}`, {
                content_idea: title,
                expected_outcome: `Viral score: ${result.viral_score}/100`,
            });
        }

        return result;
    } catch (error) {
        console.error('[ViralPredictor] Error:', error);
        return {
            viral_score: null,
            verdict: 'Analysis unavailable',
            verdict_reason: 'Could not complete viral prediction. Check your API connection and try again.',
            what_will_kill_it: ['Could not analyze — please retry'],
            what_will_save_it: ['Could not analyze — please retry'],
        };
    }
};

// ═══════════════════════════════════════════════════════════════════════════════
// ─── STICKY FEATURE 3: FIX MY LAST VIDEO (FIX 5) ─────────────────────────────
// Creator inputs their last video's data → AI diagnoses what went wrong,
// gives exact rewrite for hook, title, thumbnail, and mid-video retention.
// This is the "daily return driver" — creators come back after every upload.
// ═══════════════════════════════════════════════════════════════════════════════

exports.fixMyLastVideo = async ({
    title,
    hook,
    actualRetention,
    actualViews,
    dropOffPoint,    // e.g. "42%" — where viewers left
    channelId = null,
}) => {
    const mem = channelId ? loadCreatorMemory(channelId) : {};
    const feedbackCtx = channelId ? buildFeedbackContext(channelId) : '';

    try {
        const completion = await groq.chat.completions.create({
            messages: [{
                role: 'system',
                content: `You are a YouTube performance surgeon. You diagnose why a video underperformed and prescribe exact, surgical fixes. You are not encouraging — you are direct and precise. You reference actual numbers. You give the creator the exact words to use, not just directions.`
            }, {
                role: 'user',
                content: `Diagnose this underperforming video and provide exact fixes.

VIDEO DATA:
Title: "${title}"
Hook (opening words): "${hook || 'Not provided'}"
Actual retention: ${actualRetention || 'Unknown'}%
Actual views: ${actualViews || 'Unknown'}
Main drop-off point: ${dropOffPoint || 'Unknown'}%
${mem.avgRetention ? `Channel benchmark retention: ${mem.avgRetention}%` : ''}
${mem.winningHookType ? `Creator's proven hook type: ${mem.winningHookType}` : ''}
${feedbackCtx}

Return ONLY valid JSON — no markdown, no explanation outside JSON:
{
  "diagnosis": {
    "primary_failure": "The #1 reason this video underperformed (1 sentence, brutal honesty)",
    "secondary_failures": ["specific issue 2", "specific issue 3"],
    "performance_vs_benchmark": "X% below/above channel average — what this means"
  },
  "hook_fix": {
    "problem": "Exactly what is wrong with the current hook",
    "rewritten_hook": "Exact new opening sentence (under 20 words)",
    "hook_type": "Question|Shock|Contrarian|Story",
    "expected_retention_lift": "+X%"
  },
  "title_fix": {
    "problem": "What the current title fails to do",
    "rewritten_title": "Exact new title",
    "why_better": "Specific psychological reason this performs better"
  },
  "mid_video_fix": {
    "drop_off_cause": "Why viewers left at ${dropOffPoint || 'that point'}",
    "re_hook_line": "Exact line to insert at that timestamp to recapture attention",
    "structural_fix": "What to change in the video structure going forward"
  },
  "thumbnail_fix": {
    "current_issue": "What the thumbnail probably fails to do (based on low CTR pattern)",
    "new_concept": "Exact visual concept that creates curiosity gap",
    "text_overlay": "Exact words to put on thumbnail (under 5 words)"
  },
  "if_you_could_repost_it": {
    "new_title": "...",
    "new_hook": "exact words ...",
    "estimated_new_retention": "X%",
    "estimated_new_views": "X-Xx improvement"
  },
  "lesson_for_next_video": "One sentence — the single thing to never do again based on this data"
}`
            }],
            model: MODELS.SMART,
            temperature: 0.25,
            max_tokens: 900,
        });

        const raw = completion.choices[0].message.content.trim();
        const jsonMatch = raw.match(/\{[\s\S]*\}/);
        if (!jsonMatch) throw new Error('No JSON in fix response');

        const result = JSON.parse(jsonMatch[0]);

        // Update creator memory with this lesson (FIX 2)
        if (channelId && result.lesson_for_next_video) {
            const mem2 = loadCreatorMemory(channelId);
            saveCreatorMemory(channelId, {
                improvementAreas: [
                    ...(mem2.improvementAreas || []).slice(-9),
                    result.lesson_for_next_video,
                ]
            });
        }

        return result;
    } catch (error) {
        console.error('[FixMyLastVideo] Error:', error);
        return {
            diagnosis: {
                primary_failure: 'Analysis unavailable — please check your API connection and retry.',
                secondary_failures: [],
                performance_vs_benchmark: 'Could not calculate',
            },
            hook_fix: { problem: 'Analysis failed', rewritten_hook: '', hook_type: '', expected_retention_lift: '' },
            lesson_for_next_video: 'Try again when the service is available.',
        };
    }
};

// ─── FEEDBACK LOOP PUBLIC API (FIX 1) ────────────────────────────────────────
// Expose these so your routes can call them when YouTube Analytics data arrives.
exports.recordActualResult = recordActualResult;
exports.loadCreatorMemory = loadCreatorMemory;
exports.saveCreatorMemory = saveCreatorMemory;

// ─── HELPERS ─────────────────────────────────────────────────────────────────

function mergeWithFallback(parsed, fallback) {
    return {
        winning_pattern: parsed.winning_pattern || fallback.winning_pattern,
        hook_analysis: parsed.hook_analysis || fallback.hook_analysis,
        scores: parsed.scores || fallback.scores,
        performance_gap: parsed.performance_gap || fallback.performance_gap,
        top_vs_low_analysis: parsed.top_vs_low_analysis || fallback.top_vs_low_analysis,
        action_plan: parsed.action_plan || fallback.action_plan,
        avoid: parsed.avoid || fallback.avoid,
        next_video_plan: parsed.next_video_plan || fallback.next_video_plan,
        content_ideas: parsed.content_ideas || fallback.content_ideas,
        confidence: parsed.confidence || fallback.confidence,
        performance: parsed.performance || fallback.performance,
        hooks: parsed.hooks || fallback.hooks,
        strategy: parsed.strategy || fallback.strategy,
        timing: parsed.timing || fallback.timing,
        winningPattern: parsed.winning_pattern || fallback.winningPattern,
        alerts: parsed.alerts || fallback.alerts,
        summary: parsed.summary || fallback.summary,
    };
}

function buildFallback(summary, m, topEx, lowEx, perfGap, hasRealData) {
    return {
        winning_pattern: {
            title: `${m.dominant_hook_type || 'Question'}-hook videos are your highest-retention format`,
            insight: hasRealData
                ? `Your top ${(summary.top_videos || []).length} videos average ${m.top_videos_avg_retention}% retention — ${perfGap} higher than your bottom performers (${m.low_videos_avg_retention}%).`
                : `Videos with ${m.dominant_hook_type || 'Question'} hooks consistently outperform other formats on your channel.`,
            why_it_works: `${m.dominant_hook_type || 'Question'} hooks trigger curiosity gaps — viewers feel compelled to stay to resolve the question.`,
            duration_range: 'Under 60s',
            hook_type: m.dominant_hook_type || 'Direct',
            multiplier: m.performance_gap_ratio || '2x better'
        },
        hook_analysis: {
            quality: summary.hookSummary?.hook_quality || 'average',
            insight: `${m.weak_hooks_ratio || 0}% of your videos fall below the 30% retention threshold.`,
            weakness_reason: 'Openers state information before creating a curiosity gap or viewer promise.',
            comparison: `Best hook type: ${m.dominant_hook_type || 'Unknown'} (avg ${m.hook_retention_by_type?.[m.dominant_hook_type] || 'N/A'}% retention).`,
            retention_by_type: m.hook_retention_by_type || {}
        },
        scores: hasRealData ? { hook_score: m.hook_score, retention_score: m.retention_score, growth_score: m.growth_score } : null,
        performance_gap: hasRealData ? {
            top_avg: m.top_videos_avg_retention,
            low_avg: m.low_videos_avg_retention,
            gap_ratio: m.performance_gap_ratio,
            explanation: `Top videos retain at ${perfGap} the rate of bottom performers. Root cause: hook structure — not topic selection.`,
            top_videos_use: ['Fast pacing in first 5s', 'Clear topic immediately'],
            low_videos_use: ['Slow intro sequences', 'Weak or confusing titles'],
            action_to_take: 'Rewrite the first 3 seconds of your scripts to be instantly engaging.'
        } : null,
        top_vs_low_analysis: {
            top_performer_example: `"${topEx.title || 'N/A'}" — ${topEx.avg_view_percentage || 0}% retention`,
            low_performer_example: `"${lowEx.title || 'N/A'}" — ${lowEx.avg_view_percentage || 0}% retention`,
            key_difference: `Hook type and opening structure account for the ${perfGap} retention gap.`
        },
        action_plan: {
            summary: `Hook quality is your primary growth blocker — replicate ${m.dominant_hook_type} hooks deliberately on every upload.`,
            steps: [
                `Rewrite the opening 15 seconds of your next 3 videos to lead with a ${m.dominant_hook_type || 'Question'} hook.`,
                `Post at ${summary.bestTime} — your audience peaks here and early velocity determines algorithmic reach.`,
                `Mirror the structure of "${topEx.title || 'your top video'}" for your next upload.`
            ]
        },
        avoid: [
            'Info-dump openings — stating facts before creating a hook or promise',
            'Single-noun titles with no curiosity gap ("Review", "Breakdown", "Setup")',
            `Posting outside the ${summary.bestTime} window — reduces early algorithmic velocity`
        ],
        next_video_plan: {
            hook: `Open with: "Most creators never look at this number — and it's why their channel stopped growing."`,
            format: summary.formatWinner || 'Long-form',
            length: '7–10 minutes',
            posting_time: summary.bestTime,
            content_idea: `Recreate the structure of "${topEx.title || 'your top video'}" on a new angle.`,
            expected_outcome: `+${m.top_videos_avg_retention > 0 ? Math.round((m.top_videos_avg_retention - (m.low_videos_avg_retention || 20)) * 0.4) : 15}–${m.top_videos_avg_retention > 0 ? Math.round((m.top_videos_avg_retention - (m.low_videos_avg_retention || 20)) * 0.6) : 25}% retention increase vs recent average`,
            structure: [
                { step: "Hook (0-3s)", detail: `Use a ${m.dominant_hook_type || 'Question'} hook.` },
                { step: "Core Content (3-20s)", detail: "Deliver value rapidly without fluff." },
                { step: "Twist/Payoff (20-30s)", detail: "Introduce a surprising fact to boost rewatches." }
            ]
        },
        content_ideas: [
            `"The ${m.dominant_hook_type} hook formula behind my highest-retention video (exact breakdown)"`,
            `"I rewrote my 5 lowest-performing hooks — here's what the data showed"`,
            `"Why ${m.top_videos_avg_retention || 40}%+ retention is achievable (and what's blocking yours)"`
        ],
        confidence: {
            score: m.videos_analyzed >= 20 ? 85 : m.videos_analyzed >= 10 ? 65 : m.videos_analyzed >= 3 ? 45 : 20,
            reason: `${m.videos_analyzed || 0} videos analyzed with ${hasRealData ? 'real YouTube Analytics retention data' : 'title-based hook classification only'}.`
        },
        performance: { problem: `Channel is at: ${summary.performanceStatus}.`, why: 'Weak hooks reduce early retention, limiting algorithmic distribution.', action: `Apply ${m.dominant_hook_type || 'Question'} hook structure to your next 3 uploads.` },
        hooks: { problem: `${m.weak_hooks_ratio || 0}% of videos fall below 30% retention.`, why: 'Openers fail to create a curiosity gap.', action: `Lead with a ${m.dominant_hook_type || 'Question'} hook in the first 5 seconds.` },
        strategy: { problem: `Winning Format: ${summary.formatWinner}`, why: 'This is the pattern that the algorithm is currently rewarding for your channel.', action: `Double down on ${summary.formatWinner} with similar topics.` },
        timing: { problem: `Optimal Posting: ${summary.bestTime}`, why: `Your audience peaks at ${summary.bestTime} — early views signal quality to the algorithm.`, action: `Schedule every upload to publish at ${summary.bestTime} to maximize launch velocity.` },
        winningPattern: { title: `${m.dominant_hook_type}-hook videos are your growth engine`, insight: `Top videos average ${m.top_videos_avg_retention}% retention.`, why_it_works: 'They create a viewer promise in the first sentence and fulfill it — triggering algorithmic amplification.' },
        alerts: { problem: (m.growth_score || 50) < 40 ? 'Growth has stalled — immediate action required.' : 'No critical alerts.', why: (m.growth_score || 50) < 40 ? 'Hook failure is suppressing reach.' : 'Metrics within healthy range.', action: (m.growth_score || 50) < 40 ? 'Run a hook A/B test this week.' : 'Maintain current upload cadence.' },
        summary: [
            `Audit last 5 videos for weak hooks`,
            `Write next 3 scripts using the recommended timeline structure`,
            `Schedule uploads strictly for ${summary.bestTime}`
        ]
    };
}

// ═══════════════════════════════════════════════════════════════════════════════
// ─── NEW AI LAB: MULTI-BRAIN ROUTER ARCHITECTURE ─────────────────────────────
// ═══════════════════════════════════════════════════════════════════════════════

const cache = new Map();
const usageLimits = { tts: new Map() }; // userIp -> count

const cacheGet = (key) => {
    if (!cache.has(key)) return null;
    const { data, expiry } = cache.get(key);
    if (Date.now() > expiry) {
        cache.delete(key);
        return null;
    }
    return data;
};

const cacheSet = (key, data, ttlMs = 86400000) => {
    cache.set(key, { data, expiry: Date.now() + ttlMs });
};

const callOpenRouterFallback = async (system, user) => {
    console.warn('⚠️ [Router] Failing over to OpenRouter...');
    const response = await axios.post('https://openrouter.ai/api/v1/chat/completions', {
        model: 'openai/gpt-3.5-turbo', // Cost-effective reliable fallback
        messages: [
            { role: 'system', content: system },
            { role: 'user', content: user }
        ]
    }, {
        headers: {
            'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
            'HTTP-Referer': 'https://creatoros-backend-rb5b.onrender.com',
            'X-Title': 'CreatorOS'
        },
        timeout: 15000
    });
    return response.data.choices[0].message.content;
};

// The brain of the operation
const executeWithFailover = async ({
    key, system, user,
    primaryEngine = 'groq', model = 'llama-3.1-8b-instant',
    timeout = 10000, isJson = false
}) => {
    if (key) {
        const cached = cacheGet(key);
        if (cached) {
            console.log(`✅ [Router] Cache hit for ${key.substring(0, 20)}...`);
            return cached;
        }
    }

    let result = '';
    let attempt = 0;
    
    while (attempt < 2) {
        try {
            if (primaryEngine === 'groq') {
                const completion = await groq.chat.completions.create({
                    messages: [
                        { role: 'system', content: system },
                        { role: 'user', content: user }
                    ],
                    model: model,
                    response_format: isJson ? { type: 'json_object' } : undefined
                }, { timeout });
                result = completion.choices[0].message.content;
                break;
            } else if (primaryEngine === 'gemini') {
                if (!genAI) throw new Error('Gemini missing');
                const geminiModel = genAI.getGenerativeModel({ model });
                const prompt = system + "\n\n" + user + (isJson ? "\nReturn valid JSON." : "");
                const res = await geminiModel.generateContent(prompt);
                result = await res.response.text();
                if (isJson) result = result.replace(/```json/g, '').replace(/```/g, '').trim();
                break;
            }
        } catch (e) {
            console.error(`❌ [Router] ${primaryEngine} failed (attempt ${attempt + 1}):`, e.message);
            attempt++;
        }
    }

    if (!result) {
        try {
            result = await callOpenRouterFallback(system, user + (isJson ? "\nReturn JSON." : ""));
            if (isJson) result = result.replace(/```json/g, '').replace(/```/g, '').trim();
        } catch (e) {
            console.error('❌ [Router] Fallback completely failed:', e.message);
            throw new Error('AI Service temporarily unavailable.');
        }
    }

    if (isJson && typeof result === 'string') {
        try {
            result = JSON.parse(result);
        } catch (e) {
            console.error('Failed to parse AI JSON', result);
            throw new Error('Invalid AI response format');
        }
    }

    if (key) cacheSet(key, result);
    return result;
};

// ─── AI LAB EXPORTS ──────────────────────────────────────────────────────────

exports.executeWithFailover = executeWithFailover;

exports.generateScript = async (topic) => {
    return executeWithFailover({
        key: `script_${topic}`,
        system: `You are an elite YouTube scriptwriter. Return structured JSON with "hook", "mainContent" (array of points), and "callToAction".`,
        user: `Write a high-retention script for: "${topic}"`,
        primaryEngine: 'groq',
        model: 'llama-3.3-70b-versatile',
        timeout: 20000,
        isJson: true
    });
};

exports.generateAIChat = async (message, context) => {
    return executeWithFailover({
        system: `You are the CreatorOS AI. Help the creator brainstorm and optimize. Keep answers concise.`,
        user: message,
        primaryEngine: 'groq',
        model: 'llama-3.1-8b-instant',
        timeout: 5000,
        isJson: false
    });
};

exports.generateHashtags = async (topic) => {
    return executeWithFailover({
        key: `hashtags_${topic}`,
        system: `You are an SEO expert. Return exactly 15 viral hashtags separated by spaces. No intro/outro.`,
        user: `Generate tags for: ${topic}`,
        primaryEngine: 'groq',
        model: 'llama-3.1-8b-instant',
        timeout: 4000,
        isJson: false
    });
};

exports.generateMetadata = async (topic) => {
    return executeWithFailover({
        key: `meta_${topic}`,
        system: `Return structured JSON with "title" (high CTR) and "description" (SEO friendly).`,
        user: `Generate metadata for: ${topic}`,
        primaryEngine: 'groq',
        model: 'llama-3.1-8b-instant',
        timeout: 6000,
        isJson: true
    });
};



exports.transcribeAudio = async (filePath) => {
    const fs = require('fs');
    try {
        const transcription = await groq.audio.transcriptions.create({
            file: fs.createReadStream(filePath),
            model: "whisper-large-v3-turbo",
            response_format: "verbose_json",
        });
        return { text: transcription.text };
    } catch (e) {
        console.error('Whisper Transcription failed:', e.message);
        throw e;
    }
};

exports.generateVoiceover = async (text, reqIp = 'default') => {
    // Basic rate limit
    const usage = usageLimits.tts.get(reqIp) || 0;
    if (usage >= 2) throw new Error('Daily TTS limit reached (2/day) to prevent quota exhaustion.');
    
    // Fake TTS generation for now as requested earlier
    usageLimits.tts.set(reqIp, usage + 1);
    return { audioBase64: 'UklGRiQAAABXQVZFZm10IBAAAAABAAEAwF0AAIC7AAACABAAZGF0YQAAAAA=', duration: 1 };
};