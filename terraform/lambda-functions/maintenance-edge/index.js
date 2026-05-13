// lambda-functions/maintenance-mode/index.js

exports.handler = (event, context, callback) => {
  const request = event.Records[0].cf.request;

  // Read maintenance mode from CloudFront custom header
  // Set via Terraform when needed — no code change required
  const maintenanceMode = request.headers["x-maintenance-mode"]?.[0]?.value === "true";

  if (maintenanceMode && request.uri !== "/maintenance.html") {
    callback(null, {
      status: "503",
      statusDescription: "Service Unavailable",
      headers: {
        "content-type": [{ key: "Content-Type", value: "text/html" }],
        "retry-after": [{ key: "Retry-After", value: "3600" }],
        "cache-control": [{ key: "Cache-Control", value: "no-store" }]
      },
      body: `
        <!DOCTYPE html>
        <html>
          <head><title>Under Maintenance</title></head>
          <body>
            <h1>We'll be back soon</h1>
            <p>Scheduled maintenance in progress. Please check back in an hour.</p>
          </body>
        </html>
      `
    });
    return;
  }

  callback(null, request);
};