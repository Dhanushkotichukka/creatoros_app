const s3Service = require('../services/s3Service');
const fs = require('fs');

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


