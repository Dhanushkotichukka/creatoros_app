const ffmpeg = require('fluent-ffmpeg');
const path = require('path');
const fs = require('fs');

/**
 * Trims a video from startTime to endTime.
 * @param {string} inputFilePath 
 * @param {string} outputFilePath 
 * @param {number} startTime (in seconds)
 * @param {number} duration (in seconds)
 */
const trimVideo = (inputFilePath, outputFilePath, startTime, duration) => {
  return new Promise((resolve, reject) => {
    ffmpeg(inputFilePath)
      .setStartTime(startTime)
      .setDuration(duration)
      .output(outputFilePath)
      .on('end', () => resolve(outputFilePath))
      .on('error', (err) => reject(err))
      .run();
  });
};

/**
 * Changes the aspect ratio of a video (e.g., 9:16 for Shorts/Reels).
 * Applies padding/blur to maintain aspect without stretching.
 */
const changeAspectRatio = (inputFilePath, outputFilePath, targetRatio = '9:16') => {
  return new Promise((resolve, reject) => {
    // Basic scaling and padding for target aspect ratios (e.g., 1080x1920 for 9:16)
    let sizeStr = '1080x1920'; 
    if (targetRatio === '16:9') sizeStr = '1920x1080';
    if (targetRatio === '1:1') sizeStr = '1080x1080';
    
    ffmpeg(inputFilePath)
      .size(sizeStr)
      .autopad('black')
      .output(outputFilePath)
      .on('end', () => resolve(outputFilePath))
      .on('error', (err) => reject(err))
      .run();
  });
};

/**
 * Burns SRT subtitles into the video track.
 */
const burnSubtitles = (inputFilePath, srtFilePath, outputFilePath) => {
  return new Promise((resolve, reject) => {
    // For Windows compatibility, path needs to be escaped properly in FFmpeg filter
    const escapedSrtPath = srtFilePath.replace(/\\/g, '\\\\').replace(/:/g, '\\:');
    
    ffmpeg(inputFilePath)
      .videoFilters(`subtitles='${escapedSrtPath}'`)
      .output(outputFilePath)
      .on('end', () => resolve(outputFilePath))
      .on('error', (err) => reject(err))
      .run();
  });
};

/**
 * Extracts a thumbnail at a specific timestamp.
 */
const extractThumbnail = (inputFilePath, outputFolder, timestamp = '00:00:01.000') => {
  return new Promise((resolve, reject) => {
    ffmpeg(inputFilePath)
      .screenshots({
        timestamps: [timestamp],
        filename: 'thumbnail.png',
        folder: outputFolder,
      })
      .on('end', () => resolve(path.join(outputFolder, 'thumbnail.png')))
      .on('error', (err) => reject(err));
  });
};

module.exports = {
  trimVideo,
  changeAspectRatio,
  burnSubtitles,
  extractThumbnail
};
