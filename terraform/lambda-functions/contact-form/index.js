const AWS = require('aws-sdk');
const https = require('https');
const ses = new AWS.SES({ region: 'us-east-1' });

exports.handler = async (event) => {
    try {
        const body = JSON.parse(event.body);
        const { name, email, message } = body;
        
        // Validate input
        if (!name || !email || !message) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({ error: 'Missing required fields' })
            };
        }
        
        // Send email via SES
        const emailParams = {
            Destination: {
                ToAddresses: [process.env.EMAIL_ADDRESS]
            },
            Message: {
                Body: {
                    Text: {
                        Data: `Name: ${name}\nEmail: ${email}\nMessage: ${message}`
                    }
                },
                Subject: {
                    Data: `Contact Form Submission from ${name}`
                }
            },
            Source: process.env.EMAIL_ADDRESS
        };
        
        await ses.sendEmail(emailParams).promise();
        
        // Send to Slack if webhook is configured
        if (process.env.SLACK_WEBHOOK_URL) {
            await sendToSlack({
                name,
                email,
                message,
                timestamp: new Date().toISOString()
            }, process.env.SLACK_WEBHOOK_URL);
        }
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ message: 'Message sent successfully' })
        };
    } catch (error) {
        console.error('Error:', error);
        
        // Send error to Slack if configured
        if (process.env.SLACK_WEBHOOK_URL) {
            await sendErrorToSlack(error, process.env.SLACK_WEBHOOK_URL);
        }
        
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ error: 'Internal server error' })
        };
    }
};

async function sendToSlack(data, webhookUrl) {
    const payload = {
        text: "📝 New Contact Form Submission",
        blocks: [
            {
                type: "header",
                text: {
                    type: "plain_text",
                    text: "📝 New Contact Form Submission",
                    emoji: true
                }
            },
            {
                type: "section",
                fields: [
                    {
                        type: "mrkdwn",
                        text: `*Name:*\n${data.name}`
                    },
                    {
                        type: "mrkdwn",
                        text: `*Email:*\n<mailto:${data.email}|${data.email}>`
                    }
                ]
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: `*Message:*\n${data.message}`
                }
            },
            {
                type: "context",
                elements: [
                    {
                        type: "mrkdwn",
                        text: `🕐 ${data.timestamp}`
                    }
                ]
            }
        ]
    };
    
    const options = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(webhookUrl, options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(data);
                } else {
                    reject(new Error(`Slack returned ${res.statusCode}`));
                }
            });
        });
        req.on('error', reject);
        req.write(JSON.stringify(payload));
        req.end();
    });
}

async function sendErrorToSlack(error, webhookUrl) {
    const payload = {
        text: "❌ Contact Form Error",
        blocks: [
            {
                type: "header",
                text: {
                    type: "plain_text",
                    text: "❌ Contact Form Processing Error",
                    emoji: true
                }
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: `*Error:*\n\`\`\`${error.message}\`\`\``
                }
            }
        ]
    };
    
    const options = {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(webhookUrl, options, (res) => {
            resolve();
        });
        req.on('error', reject);
        req.write(JSON.stringify(payload));
        req.end();
    });
}