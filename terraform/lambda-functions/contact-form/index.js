const { SESClient, SendEmailCommand } = require("@aws-sdk/client-ses");
const https = require("https");

const ses = new SESClient({ region: process.env.AWS_REGION || "us-east-1" });

exports.handler = async (event) => {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST, OPTIONS"
  };

  // Handle CORS preflight
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  try {
    const { name, email, message } = JSON.parse(event.body);

    // Validate input
    if (!name || !email || !message) {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Missing required fields" })
      };
    }

    // Send email via SES
    await ses.send(new SendEmailCommand({
      Source: process.env.EMAIL_ADDRESS,
      Destination: {
        ToAddresses: [process.env.EMAIL_ADDRESS]
      },
      Message: {
        Subject: {
          Data: `Contact Form Submission from ${name}`
        },
        Body: {
          Text: {
            Data: `Name: ${name}\nEmail: ${email}\nMessage: ${message}`
          }
        }
      }
    }));

    // Send to Slack if webhook configured
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
      headers,
      body: JSON.stringify({ message: "Message sent successfully" })
    };

  } catch (error) {
    console.error("Error:", error);

    if (process.env.SLACK_WEBHOOK_URL) {
      await sendErrorToSlack(error, process.env.SLACK_WEBHOOK_URL);
    }

    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Internal server error" })
    };
  }
};

async function sendToSlack(data, webhookUrl) {
  const payload = {
    text: "📝 New Contact Form Submission",
    blocks: [
      {
        type: "header",
        text: { type: "plain_text", text: "📝 New Contact Form Submission", emoji: true }
      },
      {
        type: "section",
        fields: [
          { type: "mrkdwn", text: `*Name:*\n${data.name}` },
          { type: "mrkdwn", text: `*Email:*\n<mailto:${data.email}|${data.email}>` }
        ]
      },
      {
        type: "section",
        text: { type: "mrkdwn", text: `*Message:*\n${data.message}` }
      },
      {
        type: "context",
        elements: [{ type: "mrkdwn", text: `🕐 ${data.timestamp}` }]
      }
    ]
  };
  return postToSlack(webhookUrl, payload);
}

async function sendErrorToSlack(error, webhookUrl) {
  const payload = {
    text: "❌ Contact Form Error",
    blocks: [
      {
        type: "header",
        text: { type: "plain_text", text: "❌ Contact Form Processing Error", emoji: true }
      },
      {
        type: "section",
        text: { type: "mrkdwn", text: `*Error:*\n\`\`\`${error.message}\`\`\`` }
      }
    ]
  };
  return postToSlack(webhookUrl, payload);
}

function postToSlack(webhookUrl, payload) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(payload);
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body)
      }
    };
    const req = https.request(webhookUrl, options, (res) => {
      res.on("data", () => {});
      res.on("end", resolve);
    });
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}