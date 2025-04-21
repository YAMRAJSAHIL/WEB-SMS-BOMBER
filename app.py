from bottle import Bottle, route, run, template, request, static_file, response
import requests
import time
import os

app = Bottle()

# API Configuration
API_URL = "https://BOOMING-API.VERCEL.APP/"
MAX_SMS_PER_REQUEST = 100

@app.route('/static/<filename:path>')
def serve_static(filename):
    return static_file(filename, root='./static')

@app.route('/')
def home():
    return template('views/index.tpl')

@app.route('/send_sms', method='POST')
def send_sms():
    try:
        number = request.forms.get('number').strip()
        count = int(request.forms.get('count', 1))
        
        # Validate phone number
        number = ''.join(filter(str.isdigit, number))  # Remove non-digits
        
        if not number:
            response.status = 400
            return {'error': 'Phone number is required'}
            
        # Check number length (10 digits without code, 12 with code)
        if len(number) not in [10, 12]:
            response.status = 400
            return {'error': 'Phone number must be 10 digits (without country code) or 12 digits (with country code)'}
            
        if count <= 0:
            response.status = 400
            return {'error': 'Count must be at least 1'}
            
        if count > MAX_SMS_PER_REQUEST:
            response.status = 400
            return {'error': f'Maximum {MAX_SMS_PER_REQUEST} SMS per request'}
        
        results = {'success': 0, 'failed': 0, 'requests': []}
        
        for i in range(1, count + 1):
            try:
                try:
                    api_response = requests.get(
                        API_URL,
                        params={'number': number, 'COUNT': 1},
                        timeout=30,
                        headers={
                            'Accept': 'application/json',
                            'User-Agent': 'Mozilla/5.0'
                        }
                    )
                    
                    try:
                        response_data = api_response.json()
                    except:
                        if api_response.status_code != 200:
                            raise ValueError(f"API error (Status: {api_response.status_code})")
                        raise ValueError("Service temporarily unavailable")
                        
                    if not response_data:
                        raise ValueError("Empty response from service")
                    
                    if not api_response.ok:
                        raise ValueError(response_data.get('error', 'API request failed'))
                        
                except requests.exceptions.JSONDecodeError:
                    raise ValueError("Invalid API response format")
                except requests.exceptions.RequestException as e:
                    raise ValueError(f"Network error: {str(e)}")
                    
                if api_response.status_code == 200:
                    results['success'] += 1
                    status = f"Request {i}: Success ✅"
                else:
                    results['failed'] += 1
                    status = f"Request {i}: Failed ❌ (Status: {api_response.status_code})"
                
                results['requests'].append(status)
                time.sleep(0.5)
                
            except Exception as e:
                results['failed'] += 1
                results['requests'].append(f"Request {i}: Error ‼️ ({str(e)})")
        
        return {
            'success': True,
            'message': f'Sent {results["success"]}/{count} SMS to {number}',
            'stats': results
        }
        
    except Exception as e:
        response.status = 500
        return {'error': f'Server error: {str(e)}'}

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    run(app, host='0.0.0.0', port=port, server='gunicorn', workers=4)