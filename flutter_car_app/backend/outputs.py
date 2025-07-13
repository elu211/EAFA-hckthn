import torch
import torch.nn as nn
from torchvision import transforms, models
from PIL import Image
import io

# Global variables to load model once
MODEL = None
DEVICE = None
TRANSFORM = None

def load_model():
    """Load the trained model (called once)"""
    global MODEL, DEVICE, TRANSFORM
    
    if MODEL is not None:
        return  # Already loaded
    
    DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    
    MODEL = models.resnet18(weights=None)
    
    try:
        MODEL.fc = nn.Linear(MODEL.fc.in_features, 3)
        MODEL.load_state_dict(torch.load('best_model.pth', map_location=DEVICE))
    except RuntimeError:
        MODEL.fc = nn.Sequential(
            nn.Dropout(0.5),
            nn.Linear(MODEL.fc.in_features, 3)
        )
        MODEL.load_state_dict(torch.load('best_model.pth', map_location=DEVICE))
    
    MODEL.to(DEVICE)
    MODEL.eval()
    
    TRANSFORM = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
    ])
    
    print("✓ Model loaded successfully")

def predict(image_input, classes):
    """
    Predict using a file path or PIL image object.
    
    Args:
        image_input: Path to image OR PIL.Image OR BytesIO
        classes: List of class labels
        
    Returns:
        dict: {
            'prediction': class_name,
            'confidence': float,
            'all_probabilities': {class_name: float, ...}
        }
    """
    if MODEL is None:
        load_model()
    
    try:
        # Load and preprocess image
        if isinstance(image_input, str):
            image = Image.open(image_input).convert('RGB')
        elif isinstance(image_input, Image.Image):
            image = image_input.convert('RGB')
        elif isinstance(image_input, io.BytesIO):
            image = Image.open(image_input).convert('RGB')
        else:
            raise ValueError("Unsupported image input type")
        
        image_tensor = TRANSFORM(image).unsqueeze(0).to(DEVICE)

        with torch.no_grad():
            outputs = MODEL(image_tensor)
            probabilities = torch.softmax(outputs, dim=1)
            _, predicted = torch.max(outputs, 1)

        predicted_class = classes[predicted.item()]
        confidence = probabilities[0][predicted.item()].item()
        
        all_probs = {
            class_name: prob.item()
            for class_name, prob in zip(classes, probabilities[0])
        }

        return {
            'prediction': predicted_class,
            'confidence': confidence,
            'all_probabilities': all_probs
        }
    
    except Exception as e:
        return {
            'error': str(e),
            'prediction': None,
            'confidence': 0.0,
            'all_probabilities': {}
        }

# Test from PIL.Image instead of file path
def main(image_obj, classes):
    result = predict(image_obj, classes)
    
    if 'error' in result:
        print(f"Error: {result['error']}")
    else:
        print(f"Prediction: {result['prediction']}")
        print(f"Confidence: {result['confidence']:.3f}")
        print("All probabilities:")
        for class_name, prob in result['all_probabilities'].items():
            print(f"  {class_name}: {prob:.3f}")
    
    return result
