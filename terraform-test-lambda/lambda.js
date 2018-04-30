'use strict';
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const encoding = 'utf8';

exports.handler = function(event, context, callback) {
    const currentDate = new Date();
    const content = currentDate.toString();

    const buffer = Buffer.from(content, encoding);

    const s3Options = {
        Body: buffer,
        Bucket: 'matewilk-terraform-test-result',
        Key: 'test.txt'
    };

    console.log('invoked lambda!!');

    const onPut = (err, data) => {
        if(err) {
            console.log(err);
            callback(err);
        }

        const response = {
            statusCode: 200,
            body: JSON.stringify(data)
        };
        console.log(response);
        callback(null, response);
    };

    s3.putObject(s3Options, onPut);
};
