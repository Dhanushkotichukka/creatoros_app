const express = require('express');
const router = express.Router();
const multer = require('multer');
const mediaController = require('../controllers/mediaController');

const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

router.post('/upload', upload.single('file'), mediaController.uploadFile);
router.get('/list', mediaController.listItems);
router.delete('/delete', mediaController.deleteItem);
router.get('/download-url', mediaController.getDownloadUrl);

// ── Smart Media Search ────────────────────────────────────────────────────
// Aggregates image/video results from Unsplash, Pexels, and Pixabay.
//
// GET /api/media/search?q=<query>&type=<image|video|all>&page=1&perPage=15
// Returns: [{ source, id, url, thumbnail, type, author, authorUrl }]
const { aggregateMediaSearch } = require('../services/mediaSearchService');
router.get('/search', async (req, res) => {
  const { q, type = 'image', page = 1, perPage = 15 } = req.query;
  if (!q || !q.trim()) {
    return res.status(400).json({ error: 'Query parameter "q" is required.' });
  }
  try {
    const results = await aggregateMediaSearch(q.trim(), type, parseInt(page), parseInt(perPage));
    res.json({ results, total: results.length });
  } catch (err) {
    console.error('Media search error:', err.message);
    res.status(500).json({ error: 'Failed to fetch media results.' });
  }
});

// ── Import Stock Media into Storage ──────────────────────────────────────────
// Downloads a stock media URL and saves it to the creator's storage (Local or S3).
//
// POST /api/media/import-from-url
// Body: { url: string, fileName: string, destination: 'local' | 's3', mimeType: string }
// Returns: { success: boolean, fileName: string, storageUrl: string, storage: string }
const axios = require('axios');
const s3ServiceForImport = require('../services/s3Service');

router.post('/import-from-url', async (req, res) => {
  const { url, fileName, destination = 'local', mimeType = 'image/jpeg' } = req.body;
  if (!url || !fileName) {
    return res.status(400).json({ error: '"url" and "fileName" are required.' });
  }

  try {
    // Download the media file as a buffer
    const response = await axios.get(url, { responseType: 'arraybuffer', timeout: 30000 });
    const buffer = Buffer.from(response.data);
    const safeName = `stock_${Date.now()}_${fileName.replace(/[^a-z0-9._-]/gi, '_')}`;

    let storageUrl;
    let storageLabel;

    if (destination === 's3') {
      const key = await s3ServiceForImport.uploadToTempStorage(buffer, safeName, mimeType);
      storageUrl = await s3ServiceForImport.getPresignedUrl(s3ServiceForImport.TEMP_BUCKET, key, 604800);
      storageLabel = 'S3-Temp';
    } else {
      // Save locally
      const path = require('path');
      const fs = require('fs');
      const localDir = path.join(__dirname, '../uploads');
      if (!fs.existsSync(localDir)) fs.mkdirSync(localDir, { recursive: true });
      fs.writeFileSync(path.join(localDir, safeName), buffer);
      storageUrl = `http://127.0.0.1:3000/uploads/${safeName}`;
      storageLabel = 'Local';
    }

    res.json({
      success: true,
      fileName: safeName,
      storageUrl,
      storage: storageLabel,
      size: buffer.length,
    });
  } catch (err) {
    console.error('Import from URL error:', err.message);
    // Handle rate-limit from stock media providers
    if (err.response?.status === 429) {
      return res.status(429).json({
        error: 'Rate limit reached on this media source. Please wait a moment and try again.',
        retryAfter: err.response.headers['retry-after'] || 60,
      });
    }
    // Handle provider 403 (hot-link protection / access denied)
    if (err.response?.status === 403) {
      return res.status(403).json({ error: 'Access denied by media provider. Try downloading a different size or source.' });
    }
    res.status(500).json({ error: 'Failed to import media: ' + err.message });
  }
});

// ── OpenCut Integration ────────────────────────────────────────────────────
// Returns a signed S3 URL (or local URL) for a stored video file.
// Flutter calls this to get a URL to pass to the OpenCut editor.
//
// POST /api/media/generate-editor-url
// Body: { fileName: string, storageLabel: 'S3-Temp' | 'S3-Final' | 'Local' }
// Returns: { editorUrl: string, expiresIn: number }
router.post('/generate-editor-url', mediaController.generateEditorUrl);

// Records an exported video from OpenCut into local metadata (no re-upload needed).
// OpenCut exports are self-hosted — we just record the URL.
//
// POST /api/media/save-export
// Body: { exportUrl: string, title: string, timestamp: string }
// Returns: { success: boolean, message: string }
router.post('/save-export', mediaController.saveExport);

module.exports = router;

