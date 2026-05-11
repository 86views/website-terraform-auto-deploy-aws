// Visitor counter
async function updateVisitorCount() {
    try {
        const response = await fetch('/counter?page=home');
        const data = await response.json();
        document.getElementById('visitor-count').textContent = data.visit_count;
    } catch (error) {
        console.error('Error fetching visitor count:', error);
        document.getElementById('visitor-count').textContent = 'Error';
    }
}

// Contact form handler
document.getElementById('contactForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        message: document.getElementById('message').value
    };
    
    const statusDiv = document.getElementById('formStatus');
    statusDiv.textContent = 'Sending...';
    
    try {
        const response = await fetch('/contact', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            statusDiv.innerHTML = '<p style="color: green;">Message sent successfully!</p>';
            document.getElementById('contactForm').reset();
        } else {
            statusDiv.innerHTML = `<p style="color: red;">Error: ${data.error}</p>`;
        }
    } catch (error) {
        statusDiv.innerHTML = '<p style="color: red;">Network error. Please try again.</p>';
    }
});

// Initialize
if (document.getElementById('visitor-count')) {
    updateVisitorCount();
}