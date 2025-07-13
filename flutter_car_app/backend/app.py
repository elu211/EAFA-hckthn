from flask import Flask, request, jsonify
from flask_cors import CORS
from PIL import Image
import io
from outputs import main

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy'})

@app.route('/analyze', methods=['POST'])
def analyze_image():
    try:
        # Get the uploaded image
        if 'image' not in request.files:
            return jsonify({'error': 'No image provided'}), 400
        
        file = request.files['image']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Convert to PIL Image
        image_bytes = file.read()
        image = Image.open(io.BytesIO(image_bytes))
        
        # Define classes (same as in your model)
        classes = ['safe', 'too_close', 'danger']
        
        # Call your main function
        result = main(image, classes)
        
        # Return the result
        return jsonify(result)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("Starting server on http://localhost:5")
    app.run(host='127.0.0.1', port=5000, debug=True) 