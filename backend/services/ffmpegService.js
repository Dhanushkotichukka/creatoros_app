const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const fs = require('fs');

/**
 * Gets the duration of a video file in seconds.
 * @param {string} filePath - Path to the video file
 * @returns {Promise<number>} Duration in seconds
 */
exports.getVideoDuration = (filePath) => {
    return new Promise((resolve, reject) => {
        ffmpeg.ffprobe(filePath, (err, metadata) => {
            if (err) {
                console.error('[FFMPEG] Error probing video:', err.message);
                return reject(err);
            }
            const duration = metadata.format.duration;
            resolve(duration);
        });
    });
};

/**
 * Generates a thumbnail for a given video file.
 * @param {string} filePath - Path to the video file
 * @param {string} outputDir - Directory to save the thumbnail
 * @returns {Promise<string>} Path to the generated thumbnail
 */
exports.generateThumbnail = (filePath, outputDir) => {
    return new Promise((resolve, reject) => {
        const filename = `thumb_${Date.now()}.png`;
        const outputPath = path.join(outputDir, filename);

        if (!fs.existsSync(outputDir)) {
            fs.mkdirSync(outputDir, { recursive: true });
        }

        ffmpeg(filePath)
            .screenshots({
                timestamps: ['00:00:01.000'],
                filename: filename,
                folder: outputDir,
                size: '320x240'
            })
            .on('end', () => {
                resolve(outputPath);
            })
            .on('error', (err) => {
                console.error('[FFMPEG] Error generating thumbnail:', err.message);
                reject(err);
            });
    });
};

/**
 * Compress or optimize a video for social media publishing.
 * @param {string} inputPath - Path to the original video
 * @param {string} outputPath - Path to save the optimized video
 * @returns {Promise<string>} Path to the optimized video
 */
exports.optimizeVideo = (inputPath, outputPath) => {
    return new Promise((resolve, reject) => {
        ffmpeg(inputPath)
            .videoCodec('libx264')
            .audioCodec('aac')
            .outputOptions([
                '-preset fast',
                '-crf 28',
                '-movflags +faststart'
            ])
            .save(outputPath)
            .on('end', () => {
                resolve(outputPath);
            })
            .on('error', (err) => {
                console.error('[FFMPEG] Error optimizing video:', err.message);
                reject(err);
            });
    });
};
