const s3Service = require('../services/s3Service');
const fs = require('fs');
const path = require('path');

exports.uploadFile = async (req, res) => {
    if (!req.file) {
        return res.status(400).json({ error: 'No file uploaded' });
    }

    try {
        const fileName = `${Date.now()}-${req.file.originalname}`;
        const key = await s3Service.uploadToTempStorage(
            req.file.buffer,
            fileName,
            req.file.mimetype
        );

        res.json({
            message: 'File uploaded successfully',
            fileName: key,
            url: await s3Service.getPresignedUrl(s3Service.TEMP_BUCKET, key)
        });
    } catch (error) {
        console.error('Upload Error:', error);
        res.status(500).json({ error: 'Failed to upload file to storage' });
    }
};

exports.deleteItem = async (req, res) => {
    const { fileName, storage } = req.body;
    if (!fileName) return res.status(400).json({ error: 'fileName is required' });
    try {
        await s3Service.deleteStorageObject(fileName, storage || 'Local');
        res.json({ success: true, message: `Deleted ${fileName}` });
    } catch (error) {
        console.error('Delete Error:', error);
        res.status(500).json({ error: 'Failed to delete file' });
    }
};

exports.getDownloadUrl = async (req, res) => {
    const { fileName, storage } = req.query;
    if (!fileName) return res.status(400).json({ error: 'fileName is required' });
    try {
        const url = await s3Service.getDownloadUrl(fileName, storage || 'Local');
        res.json({ url });
    } catch (error) {
        console.error('Download URL Error:', error);
        res.status(500).json({ error: 'Failed to generate download URL' });
    }
};

exports.listItems = async (req, res) => {
    try {
        const items = await s3Service.listStorageObjects();
        res.json({ items });
    } catch (error) {
        console.error('List Error:', error);
        res.status(500).json({ error: 'Failed to list storage items' });
    }
};

// ── OpenCut Integration ─────────────────────────────────────────────────────

/**
 * POST /api/media/generate-editor-url
 * Generates a fresh signed URL for a stored video file.
 * Flutter passes this URL to VideoEditorScreen → OpenCut pre-loads the video.
 * Body: { fileName: string, storageLabel: 'S3-Temp' | 'S3-Final' | 'Local' }
 */
exports.generateEditorUrl = async (req, res) => {
    const { fileName, storageLabel } = req.body;
    if (!fileName) return res.status(400).json({ error: 'fileName is required' });

    try {
        // 1-hour signed URL is plenty for an editing session
        const editorUrl = await s3Service.getDownloadUrl(
            fileName,
            storageLabel || 'Local'
        );
        res.json({
            editorUrl,
            expiresIn: 3600,
            fileName,
        });
    } catch (error) {
        console.error('Generate editor URL error:', error);
        res.status(500).json({ error: 'Failed to generate editor URL' });
    }
};

/**
 * POST /api/media/save-export
 * Records an OpenCut-exported video URL into a local JSON log.
 * (The file itself is already on the OpenCut host — no re-upload needed.)
 * Body: { exportUrl: string, title: string, timestamp: string }
 */
exports.saveExport = async (req, res) => {
    const { exportUrl, title, timestamp } = req.body;
    if (!exportUrl) return res.status(400).json({ error: 'exportUrl is required' });

    try {
        const exportsLogPath = path.join(__dirname, '../uploads/opencut_exports.json');

        // Load existing log or start fresh
        let exports = [];
        if (fs.existsSync(exportsLogPath)) {
            try {
                exports = JSON.parse(fs.readFileSync(exportsLogPath, 'utf8'));
            } catch (_) { exports = []; }
        }

        // Prepend new entry (newest first)
        exports.unshift({
            id: Date.now().toString(),
            exportUrl,
            title: title || 'Edited Video',
            timestamp: timestamp || new Date().toISOString(),
            source: 'opencut',
        });

        // Keep at most 100 export records
        if (exports.length > 100) exports = exports.slice(0, 100);

        fs.writeFileSync(exportsLogPath, JSON.stringify(exports, null, 2));

        res.json({
            success: true,
            message: 'Export recorded successfully',
            totalExports: exports.length,
        });
    } catch (error) {
        console.error('Save export error:', error);
        res.status(500).json({ error: 'Failed to record export' });
    }
};
