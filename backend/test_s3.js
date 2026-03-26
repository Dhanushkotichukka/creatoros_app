const { S3Client, ListObjectsV2Command } = require("@aws-sdk/client-s3");
require('dotenv').config();

const s3Client = new S3Client({
    region: process.env.AWS_REGION || "us-east-1",
    credentials: {
        accessKeyId: process.env.AWS_ACCESS_KEY_ID,
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    }
});

const TEMP_BUCKET = process.env.AWS_S3_BUCKET_TEMP;

async function test() {
    console.log(`Testing Bucket: ${TEMP_BUCKET}`);
    try {
        const command = new ListObjectsV2Command({ Bucket: TEMP_BUCKET });
        const res = await s3Client.send(command);
        console.log('Results:', JSON.stringify(res.Contents, null, 2));
    } catch (e) {
        console.error('Error:', e.message);
    }
}

test();
