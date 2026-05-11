const AWS = require('aws-sdk');
const dynamodb = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    try {
        const pageId = event.queryStringParameters?.page || 'home';
        const tableName = process.env.TABLE_NAME;
        
        // Update visitor count
        const params = {
            TableName: tableName,
            Key: { page_id: pageId },
            UpdateExpression: 'ADD visit_count :inc',
            ExpressionAttributeValues: {
                ':inc': 1
            },
            ReturnValues: 'UPDATED_NEW'
        };
        
        const result = await dynamodb.update(params).promise();
        
        // Get current count
        const getParams = {
            TableName: tableName,
            Key: { page_id: pageId }
        };
        
        const getResult = await dynamodb.get(getParams).promise();
        const count = getResult.Item?.visit_count || 0;
        
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({ 
                page_id: pageId, 
                visit_count: count 
            })
        };
    } catch (error) {
        console.error('Error:', error);
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