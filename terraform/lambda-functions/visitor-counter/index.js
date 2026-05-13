const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, UpdateCommand, GetCommand } = require("@aws-sdk/lib-dynamodb");

const client = new DynamoDBClient({ region: process.env.AWS_REGION || "us-east-1" });
const dynamo = DynamoDBDocumentClient.from(client);

exports.handler = async (event) => {
  const headers = {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET, OPTIONS"
  };

  // Handle CORS preflight
  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 200, headers, body: "" };
  }

  try {
    const pageId = event.queryStringParameters?.page || "home";
    const tableName = process.env.TABLE_NAME;

    if (!tableName) {
      throw new Error("TABLE_NAME environment variable not set");
    }

    // ✅ Increment and return in one operation — no need for second GET
    const result = await dynamo.send(new UpdateCommand({
      TableName: tableName,
      Key: { page_id: pageId },
      UpdateExpression: "ADD visit_count :inc",
      ExpressionAttributeValues: { ":inc": 1 },
      ReturnValues: "UPDATED_NEW"
    }));

    const count = result.Attributes?.visit_count || 0;

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({
        page_id: pageId,
        visit_count: count
      })
    };

  } catch (error) {
    console.error("Error:", error);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Internal server error" })
    };
  }
};