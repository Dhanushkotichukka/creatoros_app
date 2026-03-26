const { S3Client, PutObjectCommand, GetObjectCommand, ListObjectsV2Command } = require("@aws-sdk/client-s3");
const { getSignedUrl } = require("@aws-sdk/s3-request-presigner");
const fs = require('fs');
const path = require('path');

const isAWSConfigured = process.env.AWS_ACCESS_KEY_ID && process.env.AWS_ACCESS_KEY_ID !== 'your_aws_access_key_here';

let s3Client = null;
if (isAWSConfigured) {
    s3Client = new S3Client({
        region: process.env.AWS_REGION || "us-east-1",
        credentials: {
            accessKeyId: process.env.AWS_ACCESS_KEY_ID,
            secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
        }
    });
}

const TEMP_BUCKET = process.env.AWS_S3_BUCKET_TEMP || "creatoros-temp-assets";
const FINAL_BUCKET = process.env.AWS_S3_BUCKET_FINAL || "creatoros-final-assets";

// Local storage directory
const LOCAL_STORAGE_DIR = path.join(__dirname, '../uploads');
if (!fs.existsSync(LOCAL_STORAGE_DIR)) {
    fs.mkdirSync(LOCAL_STORAGE_DIR, { recursive: true });
}

const uploadToTempStorage = async (fileBuffer, fileName, mimeType) => {
    if (isAWSConfigured) {
        try {
            const command = new PutObjectCommand({
                Bucket: TEMP_BUCKET,
                Key: fileName,
                Body: fileBuffer,
                ContentType: mimeType,
            });
            await s3Client.send(command);
            return fileName;
        } catch (s3Error) {
            console.warn('S3 Upload failed, falling back to local:', s3Error.message);
        }
    }

    // Local Fallback
    const filePath = path.join(LOCAL_STORAGE_DIR, fileName);
    fs.writeFileSync(filePath, fileBuffer);
    return fileName;
};

const uploadToFinalStorage = async (fileBuffer, fileName, mimeType) => {
    if (isAWSConfigured) {
        try {
            const command = new PutObjectCommand({
                Bucket: FINAL_BUCKET,
                Key: fileName,
                Body: fileBuffer,
                ContentType: mimeType,
            });
            await s3Client.send(command);
            return fileName;
        } catch (s3Error) {
            console.warn('S3 Final Upload failed, falling back to local:', s3Error.message);
        }
    }

    // Local Fallback
    const filePath = path.join(LOCAL_STORAGE_DIR, fileName);
    fs.writeFileSync(filePath, fileBuffer);
    return fileName;
};

const getPresignedUrl = async (bucket, fileName, expiresInSeconds = 3600) => {
    if (isAWSConfigured) {
        try {
            const command = new GetObjectCommand({
                Bucket: bucket,
                Key: fileName,
            });
            return await getSignedUrl(s3Client, command, { expiresIn: expiresInSeconds });
        } catch (s3Error) {
            console.warn('S3 URL generation failed, falling back to local:', s3Error.message);
        }
    }

    // Local fallback: return the local server URL
    return `http://localhost:3000/uploads/${fileName}`;
};

const listStorageObjects = async () => {
    let s3Items = [];
    if (isAWSConfigured) {
        const buckets = [
            { name: TEMP_BUCKET, label: 'S3-Temp' },
            { name: FINAL_BUCKET, label: 'S3-Final' }
        ];

        for (const bucket of buckets) {
            try {
                const command = new ListObjectsV2Command({ Bucket: bucket.name });
                const res = await s3Client.send(command);
                if (res.Contents) {
                    s3Items.push(...res.Contents.map(item => ({
                        name: item.Key,
                        size: item.Size,
                        lastModified: item.LastModified,
                        url: `https://${bucket.name}.s3.amazonaws.com/${item.Key}`,
                        storage: bucket.label
                    })));
                }
            } catch (err) {
                console.warn(`S3 List failed for bucket ${bucket.name}:`, err.message);
            }
        }
    }

    // Always include local items as well (unified view)
    let localItems = [];
    if (fs.existsSync(LOCAL_STORAGE_DIR)) {
        const files = fs.readdirSync(LOCAL_STORAGE_DIR);
        localItems = files.map(file => {
            const stats = fs.statSync(path.join(LOCAL_STORAGE_DIR, file));
            return {
                name: file,
                size: stats.size,
                lastModified: stats.mtime,
                url: `http://localhost:3000/uploads/${file}`,
                storage: 'Local'
            };
        });
    }

    return [...s3Items, ...localItems];
};

module.exports = {
    uploadToTempStorage,
    uploadToFinalStorage,
    getPresignedUrl,
    listStorageObjects,
    TEMP_BUCKET,
    FINAL_BUCKET
};
