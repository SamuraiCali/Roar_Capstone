import { GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { s3Client } from "../config/s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

export const getPresignedDownloadUrl = async (
  key: string,
  expiresIn: number = 60,
) => {
  const command = new GetObjectCommand({
    Bucket: process.env.S3_BUCKET_NAME!,
    Key: key,
  });

  const url = await getSignedUrl(s3Client, command, { expiresIn: expiresIn });
  return url;
};

export const getPresignedUploadUrlHelper = async (
  key: string,
  fileType: string,
  expiresIn: number = 60,
) => {
  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET_NAME!,
    Key: key,
    ContentType: fileType,
  });

  const url = await getSignedUrl(s3Client, command, { expiresIn: expiresIn });
  return url;
};
