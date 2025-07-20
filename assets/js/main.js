document.addEventListener('DOMContentLoaded', function() {
    // Load today's devotional into the main page
    if (document.getElementById('main-content')) {
        fetch('today.html')
            .then(response => response.text())
            .then(data => {
                const parser = new DOMParser();
                const doc = parser.parseFromString(data, 'text/html');
                const devotionalArticle = doc.querySelector('.devotional');
                if (devotionalArticle) {
                    document.getElementById('main-content').appendChild(devotionalArticle);
                }
            })
            .catch(error => console.error('Error loading today\'s devotional:', error));
    }
});

