const Script = require('../models/Script');

exports.saveScript = async (req, res) => {
    try {
        const userId = req.user?.id;
        const { topicTitle, hook, mainContent, callToAction, trendReason, aiRating, language } = req.body;

        // Map frontend fields → MongoDB schema fields
        const content = [
            hook ? `HOOK:\n${hook}` : '',
            mainContent ? `\nSCRIPT:\n${mainContent}` : '',
            callToAction ? `\nCALL TO ACTION:\n${callToAction}` : '',
        ].filter(Boolean).join('\n');

        const newScript = await Script.create({
            userId,
            title: topicTitle || 'Untitled Script',
            topic: topicTitle,
            content,
            hook,
            body: mainContent,
            callToAction,
            aiModelUsed: `Groq/Gemini (Rating: ${aiRating || 'N/A'})`,
            status: 'draft',
        });
        res.status(201).json({ message: 'Script saved successfully', script: newScript });
    } catch (error) {
        console.error('Error saving script:', error);
        res.status(500).json({ error: 'Failed to save script', details: error.message });
    }
};

exports.getScripts = async (req, res) => {
    try {
        const userId = req.user?.id;
        const scripts = await Script.find({ userId }).sort({ createdAt: -1 });
        // Map back to frontend shape
        const mapped = scripts.map(s => ({
            id: s._id,
            topicTitle: s.title,
            hook: s.hook || '',
            mainContent: s.body || '',
            callToAction: s.callToAction || '',
            aiRating: s.aiModelUsed?.match(/Rating: ([0-9.]+)/)?.at(1) || '0.0',
            createdAt: s.createdAt,
        }));
        res.status(200).json({ scripts: mapped });
    } catch (error) {
        console.error('Error fetching scripts:', error);
        res.status(500).json({ error: 'Failed to fetch scripts' });
    }
};

exports.updateScript = async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = req.body;
        const script = await Script.findByIdAndUpdate(id, updatedData, { new: true });
        if (!script) return res.status(404).json({ error: 'Script not found' });
        res.status(200).json({ message: 'Script updated successfully', script });
    } catch (error) {
        console.error('Error updating script:', error);
        res.status(500).json({ error: 'Failed to update script' });
    }
};

exports.deleteScript = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user?.id;
        const script = await Script.findOneAndDelete({ _id: id, userId });
        if (!script) return res.status(404).json({ error: 'Script not found' });
        res.status(200).json({ message: 'Script deleted successfully' });
    } catch (error) {
        console.error('Error deleting script:', error);
        res.status(500).json({ error: 'Failed to delete script' });
    }
};

