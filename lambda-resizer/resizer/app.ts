import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { S3 } from 'aws-sdk';

// eslint-disable-next-line @typescript-eslint/no-var-requires
import sharp from 'sharp';

/**
 *
 * Event doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
 * @param {Object} event - API Gateway Lambda Proxy Input Format
 *
 * Return doc: https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
 * @returns {Object} object - API Gateway Lambda Proxy Output Format
 *
 */

interface QueryStringParameters {
    key: string;
}

// interaface of the environment variables
interface EnvironmentVariables {
    BUCKET_NAME: string;
    TARGET_BUCKET_NAME: string;
    ALLOWED_DIMENSIONS: string;
    CDN_URL: string;
}

const { BUCKET_NAME, TARGET_BUCKET_NAME, ALLOWED_DIMENSIONS, CDN_URL } = process.env as unknown as EnvironmentVariables;

const ALLOWED_DIMENSIONS_ARRAY = ALLOWED_DIMENSIONS.split(',');

const ALLOWED_DIMENSIONS_DICT: Map<string, { width: number; height: number }> = new Map();

ALLOWED_DIMENSIONS_ARRAY.forEach((dimension) => {
    const [width, height] = dimension.split('x');
    ALLOWED_DIMENSIONS_DICT.set(dimension, {
        width: parseInt(width, 10),
        height: parseInt(height, 10),
    });
});

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const lambdaHandler = async (event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> => {
    let response: APIGatewayProxyResult;
    try {
        // get the query string parameters
        const { key } = event.queryStringParameters as unknown as QueryStringParameters;

        if (!key) {
            throw new Error('No key provided');
        }

        // key is of form: resized/100x100/cards/05a77f61-19b6-4f9c-a354-c21e5b0b485e_pRMt8lzLTfSMonfaEt2I/bronze_19.png
        const [, dimension, ...imageKey] = key.split('/');

        console.log({
            dimension,
            imageKey: imageKey.join('/'),
        });

        // check if the dimensions are allowed
        if (!ALLOWED_DIMENSIONS_DICT.has(dimension)) {
            throw new Error('Dimensions not allowed');
        }

        // get the image from S3
        const s3 = new S3();
        const s3Object = await s3
            .getObject({
                Bucket: BUCKET_NAME,
                Key: imageKey.join('/'),
            })
            .promise();

        if (!s3Object.Body) {
            throw new Error('Address unknown');
        }

        // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
        const { height, width } = ALLOWED_DIMENSIONS_DICT.get(dimension)!;

        // resize the image
        const resizedImage = await sharp(s3Object.Body as Buffer)
            .resize(width, height, {
                fit: sharp.fit.inside,
                withoutEnlargement: true,
            })
            .toFormat('png')
            .toBuffer();

        // save the resized image to S3
        await s3
            .putObject({
                Body: resizedImage,
                Bucket: TARGET_BUCKET_NAME,
                ContentType: 'image/png',
                Key: key,
                ACL: 'public-read',
            })
            .promise();

        // return the resized image
        response = {
            statusCode: 301,
            headers: {
                Location: `${CDN_URL}/${key}`,
            },
            body: '',
        };
    } catch (err: unknown) {
        console.error(err);
        response = {
            statusCode: 500,
            body: JSON.stringify({
                message: err instanceof Error ? err.message : 'some error happened',
            }),
        };
    }

    return response;
};
