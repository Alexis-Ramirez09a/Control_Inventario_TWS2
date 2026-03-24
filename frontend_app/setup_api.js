const fs = require('fs');
const http = require('http');

http.get('http://localhost:4040/api/tunnels', (resp) => {
  let data = '';
  resp.on('data', (chunk) => data += chunk);
  resp.on('end', () => {
    const json = JSON.parse(data);
    const url = json.tunnels[0].public_url;
    const content = `class ApiConfig {\n  static const String baseUrl = '${url}/api';\n}\n`;
    fs.mkdirSync('C:/Users/ASUS/Desktop/Control_Inventario/frontend_app/lib/core', { recursive: true });
    fs.writeFileSync('C:/Users/ASUS/Desktop/Control_Inventario/frontend_app/lib/core/api_config.dart', content);
    console.log('API Config saved:', url);
  });
});
