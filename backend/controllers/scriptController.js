const Script = require('../models/Script');

exports.saveScript = async (req, res) => {
    try {
        const scriptData = req.body;
        const newScript = await Script.create(scriptData);
        res.status(201).json({ message: 'Script saved successfully', script: newScript });
    } catch (error) {
        console.error('Error saving script:', error);
        res.status(500).json({ error: 'Failed to save script' });
    }
};

exports.getScripts = async (req, res) => {
    try {
        const scripts = await Script.findAll({ order: [['createdAt', 'DESC']] });
        res.status(200).json({ scripts });
    } catch (error) {
        console.error('Error fetching scripts:', error);
        res.status(500).json({ error: 'Failed to fetch scripts' });
    }
};

exports.updateScript = async (req, res) => {
    try {
        const { id } = req.params;
        const updatedData = req.body;
        
        const script = await Script.findByPk(id);
        if (!script) return res.status(404).json({ error: 'Script not found' });

        await script.update(updatedData);
        res.status(200).json({ message: 'Script updated successfully', script });
    } catch (error) {
        console.error('Error updating script:', error);
        res.status(500).json({ error: 'Failed to update script' });
    }
};

exports.deleteScript = async (req, res) => {
    try {
        const { id } = req.params;
        const script = await Script.findByPk(id);
        if (!script) return res.status(404).json({ error: 'Script not found' });

        await script.destroy();
        res.status(200).json({ message: 'Script deleted successfully' });
    } catch (error) {
        console.error('Error deleting script:', error);
        res.status(500).json({ error: 'Failed to delete script' });
    }
};
