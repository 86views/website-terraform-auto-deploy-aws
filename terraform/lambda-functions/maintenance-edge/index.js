// CloudFront@Edge function for maintenance mode
exports.handler = (event, context, callback) => {
    const request = event.Records[0].cf.request;
    const response = event.Records[0].cf.response;
    
    // Check if maintenance mode is enabled via environment or parameter
    // This would typically check DynamoDB or SSM Parameter Store
    
    const isMaintenanceMode = false; // Set based on external config
    
    if (isMaintenanceMode && request.uri !== '/maintenance.html') {
        const maintenanceResponse = {
            status: '503',
            statusDescription: 'Service Unavailable',
            headers: {
                'content-type': [{
                    key: 'Content-Type',
                    value: 'text/html'
                }],
                'retry-after': [{
                    key: 'Retry-After',
                    value: '3600'
                }]
            },
            body: '<html><body><h1>Under Maintenance</h1><p>Please check back later.</p></body></html>'
        };
        callback(null, maintenanceResponse);
        return;
    }
    
    callback(null, request);
};