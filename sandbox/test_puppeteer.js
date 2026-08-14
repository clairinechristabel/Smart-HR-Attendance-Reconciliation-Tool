const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox'] });
    const page = await browser.newPage();
    
    page.on('console', msg => console.log('BROWSER CONSOLE:', msg.text()));
    page.on('pageerror', error => console.log('BROWSER ERROR:', error.message));
    page.on('requestfailed', request => console.log('BROWSER REQUEST FAILED:', request.url(), request.failure().errorText));

    // Wait until network is idle
    await page.goto('https://pure-eyrie-75921-69c00a3a5b8a.herokuapp.com/hr-dashboard.html', { waitUntil: 'networkidle0' });
    
    // Inject auth token (mocking)
    await page.evaluate(() => {
        localStorage.setItem('auth_token', 'mock_token');
        localStorage.setItem('user', JSON.stringify({
            email: 'admin@foodangel.hk',
            role: 'HR_ADMIN',
            fullName: 'Sarah Au',
            location: 'HQ'
        }));
    });
    
    // Reload to apply token
    await page.goto('https://pure-eyrie-75921-69c00a3a5b8a.herokuapp.com/hr-dashboard.html', { waitUntil: 'networkidle0' });

    // Wait 2 seconds for any async renders
    await new Promise(r => setTimeout(r, 2000));
    
    await browser.close();
})();
