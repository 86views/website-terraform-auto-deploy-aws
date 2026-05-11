const https = require('https');

exports.handler = async (event) => {
    const slackWebhookUrl = process.env.SLACK_WEBHOOK_URL;
    
    if (!slackWebhookUrl) {
        console.error('SLACK_WEBHOOK_URL not configured');
        return { statusCode: 500, body: 'Slack webhook not configured' };
    }
    
    try {
        // Parse the event (supports multiple sources)
        let message = {};
        
        if (event.Records && event.Records[0].EventSource === 'aws:sns') {
            // SNS message
            const snsMessage = JSON.parse(event.Records[0].Sns.Message);
            message = formatSNSMessage(snsMessage);
        } else if (event.httpMethod === 'POST' && event.path === '/contact') {
            // Contact form submission
            const body = JSON.parse(event.body);
            message = formatContactMessage(body);
        } else if (event.detail) {
            // CloudWatch event
            message = formatCloudWatchMessage(event.detail);
        } else {
            // Generic message
            message = {
                text: `*AWS Notification*\n${JSON.stringify(event, null, 2)}`,
                color: "#36a64f"
            };
        }
        
        // Send to Slack
        await sendSlackMessage(slackWebhookUrl, message);
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ message: 'Notification sent to Slack' })
        };
    } catch (error) {
        console.error('Error sending to Slack:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: 'Failed to send notification' })
        };
    }
};

function formatContactMessage(body) {
    const { name, email, message } = JSON.parse(body);
    const timestamp = new Date().toISOString();
    
    return {
        text: `*📝 New Contact Form Submission*`,
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
                        text: `*Name:*\n${name}`
                    },
                    {
                        type: "mrkdwn",
                        text: `*Email:*\n<mailto:${email}|${email}>`
                    }
                ]
            },
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: `*Message:*\n${message}`
                }
            },
            {
                type: "context",
                elements: [
                    {
                        type: "mrkdwn",
                        text: `🕐 ${timestamp}`
                    }
                ]
            }
        ],
        color: "#36a64f"
    };
}

function formatSNSMessage(message) {
    let color = "#36a64f"; // Green for success
    let title = "✅ AWS Notification";
    
    if (message.AlarmName) {
        // CloudWatch Alarm
        title = `🚨 ${message.AlarmName}`;
        color = message.NewStateValue === "ALARM" ? "#ff0000" : "#36a64f";
    } else if (message.errorMessage) {
        // Lambda error
        title = "❌ Lambda Error";
        color = "#ff0000";
    }
    
    return {
        text: title,
        attachments: [{
            color: color,
            title: title,
            text: JSON.stringify(message, null, 2),
            fields: [
                {
                    title: "Timestamp",
                    value: new Date().toISOString(),
                    short: true
                }
            ]
        }]
    };
}

function formatCloudWatchMessage(detail) {
    let color = "#36a64f";
    let title = "📊 CloudWatch Event";
    
    if (detail.errorMessage) {
        color = "#ff0000";
        title = "❌ Error Detected";
    }
    
    return {
        text: title,
        attachments: [{
            color: color,
            title: title,
            text: `\`\`\`${JSON.stringify(detail, null, 2)}\`\`\``
        }]
    };
}

async function sendSlackMessage(webhookUrl, message) {
    const payload = JSON.stringify(message);
    
    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Content-Length': Buffer.byteLength(payload)
        }
    };
    
    return new Promise((resolve, reject) => {
        const req = https.request(webhookUrl, options, (res) => {
            let data = '';
            res.on('data', (chunk) => data += chunk);
            res.on('end', () => {
                if (res.statusCode === 200) {
                    resolve(data);
                } else {
                    reject(new Error(`Slack API returned ${res.statusCode}: ${data}`));
                }
            });
        });
        
        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}