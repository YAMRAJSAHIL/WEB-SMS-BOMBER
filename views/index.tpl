<!DOCTYPE html>
<html>
<head>
    <title>SMS Bomber by YAMRAJSAHIL2</title>
    <link rel="stylesheet" href="/static/style.css">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
    <div class="container">
        <div class="neon-title-container">
            <h1 class="neon-title">💣 SMS BOMBER PRO</h1>
        </div>
        <p class="neon-subtitle">Powered by YAMRAJ SAHIL</p>
        
        <div class="bomber-box">
            <form id="smsForm">
                <div class="form-group">
                    <label for="number" class="neon-label">📱 Target Number:</label>
                    <input type="text" id="number" name="number" class="neon-input" 
                           placeholder="Enter phone number with country code" 
                           pattern="[0-9]{10,12}"
                           title="Please enter 10 digits (without country code) or 12 digits (with country code)"
                           maxlength="12"
                           oninput="this.value = this.value.replace(/[^0-9]/g, '')"
                           required>
                </div>
                
                <div class="form-group">
                    <label for="count" class="neon-label">💬 Message Count (Max 100):</label>
                    <input type="number" id="count" name="count" class="neon-input" 
                           value="10" min="1" max="100">
                </div>
                
                <div class="button-group">
                    <button type="submit" class="neon-button">🚀 FIRE SMS</button>
                    <button type="button" id="stopButton" class="stop-button">⚡ STOP</button>
                </div>
            </form>
            
            <div id="result" class="result-box"></div>
            <div id="stats" class="stats-box" style="display:none;">
                <h3>📊 Attack Report</h3>
                <div class="stat-row">
                    <span class="stat-label">Successful:</span>
                    <span id="success-count" class="stat-value success">0</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Failed:</span>
                    <span id="failed-count" class="stat-value error">0</span>
                </div>
                <div class="stat-row">
                    <span class="stat-label">Total:</span>
                    <span id="total-count" class="stat-value">0</span>
                </div>
            </div>
            
            <div id="requests" class="requests-box" style="display:none;">
                <h3>📜 Request Logs</h3>
                <div id="request-logs"></div>
            </div>
        </div>
        
        <div class="footer">
            <p>👨‍💻 Developer: <a href="https://t.me/YAMRAJSAHIL2" class="highlight">Sahil</a></p>
            <p>🎨 Web Designer: <a href="https://t.me/YAMRAJSAHIL2" class="highlight">@YAMRAJSAHIL2</a></p>
        </div>
    </div>

    <script>
        let isAttackRunning = false;
        let currentRequest = null;
        let successCount = 0;
        let failedCount = 0;
        let totalRequests = 0;
        let lastSuccessfulIndex = 0;

        document.getElementById('stopButton').addEventListener('click', function() {
            if (!isAttackRunning) {
                document.getElementById('result').innerHTML = '<div class="error">⚠️ No running process found</div>';
                return;
            }
            isAttackRunning = false;
            if (currentRequest) {
                currentRequest.abort();
            }
            document.getElementById('result').innerHTML = '<div class="success">🛑 Attack stopped. Sent ' + successCount + ' out of ' + totalRequests + ' messages.</div>';
        });

        document.getElementById('smsForm').addEventListener('submit', async function(e) {
            e.preventDefault();
            
            const number = document.getElementById('number').value.trim();
            const count = parseInt(document.getElementById('count').value);
            const resultDiv = document.getElementById('result');
            const statsDiv = document.getElementById('stats');
            const requestsDiv = document.getElementById('requests');
            const requestLogs = document.getElementById('request-logs');
            
            // Reset UI
            resultDiv.innerHTML = '<div class="loading">⚡ Sending attack on '+number+'...</div>';
            statsDiv.style.display = 'none';
            requestsDiv.style.display = 'none';
            requestLogs.innerHTML = '';
            
            isAttackRunning = true;
            successCount = 0;
            failedCount = 0;
            totalRequests = count;
            lastSuccessfulIndex = 0;
            // Stop button is now always visible

            async function sendSingleSMS(index) {
                if (!isAttackRunning) return null;
                
                try {
                    currentRequest = new AbortController();
                    const response = await fetch('/send_sms', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                        },
                        body: `number=${encodeURIComponent(number)}&count=1`,
                        signal: currentRequest.signal
                    });
                    
                    if (!response.ok) {
                        throw new Error(`HTTP error! status: ${response.status}`);
                    }
                    
                    const data = await response.json();
                    if (data.error) {
                        throw new Error(data.error);
                    }
                    
                    successCount++;
                    lastSuccessfulIndex = index;
                    return true;
                } catch (error) {
                    if (error.name === 'AbortError') return null;
                    
                    if (error.message.includes('Unexpected token')) {
                        await new Promise(resolve => setTimeout(resolve, 2000));
                        return await sendSingleSMS(index);
                    }
                    
                    failedCount++;
                    return false;
                }
            }

            // Validate phone number
            if (!/^[0-9]{10,12}$/.test(number)) {
                resultDiv.innerHTML = '<div class="error">⚠️ Invalid phone number! Must be 10-12 digits.</div>';
                return;
            }

            try {
                const logs = [];
                for (let i = lastSuccessfulIndex; i < count && isAttackRunning; i++) {
                    const result = await sendSingleSMS(i);
                    if (result === null) break; // Stopped
                    
                    const log = result ? 
                        `Request ${i + 1}: Success ✅` : 
                        `Request ${i + 1}: Failed ❌`;
                    logs.push(log);
                    
                    // Update logs
                    const logItem = document.createElement('p');
                    logItem.textContent = log;
                    requestLogs.appendChild(logItem);
                    requestsDiv.style.display = 'block';
                    
                    // Update stats
                    document.getElementById('success-count').textContent = successCount;
                    document.getElementById('failed-count').textContent = failedCount;
                    document.getElementById('total-count').textContent = count;
                    statsDiv.style.display = 'block';
                    
                    // Add small delay between requests
                    await new Promise(resolve => setTimeout(resolve, 500));
                }
                
                // Final summary
                const summary = isAttackRunning ? 
                    `🎯 Attack completed! Sent ${successCount} out of ${count} messages successfully.` :
                    `🛑 Attack stopped. Sent ${successCount} out of ${count} messages.`;
                    
                resultDiv.innerHTML = `<div class="success">${summary}</div>`;
            } catch (error) {
                resultDiv.innerHTML = `<div class="error">💥 Network Error: ${error.message}</div>`;
            }
        });
    </script>
</body>
</html>
