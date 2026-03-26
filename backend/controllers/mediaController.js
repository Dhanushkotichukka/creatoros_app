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

exports.listItems = async (req, res) => {
    try {
        const items = await s3Service.listStorageObjects();
        res.json({ items });
    } catch (error) {
        console.error('List Error:', error);
        res.status(500).json({ error: 'Failed to list storage items' });
    }
};
