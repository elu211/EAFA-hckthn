import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, Dataset

# Vision & image processing
from torchvision import transforms, models
from PIL import Image
import cv2
import numpy as np

# Utils
import os



class SimpleDataset(Dataset):

    def __init__(self, data_dir, classes, transform=None):
        self.transform = transform
        self.images = []
        self.labels = []
        self.classes = classes

        
        for class_idx, class_name in enumerate(self.classes):
            class_path = os.path.join(data_dir, class_name)
            if os.path.exists(class_path):
                for img_file in os.listdir(class_path):
                    if img_file.endswith(('.jpg', '.jpeg', '.png')):
                        self.images.append(os.path.join(class_path, img_file))
                        self.labels.append(class_idx)
        
        print(f"Found {len(self.images)} images")
    
    def __len__(self):
        return len(self.images)
    
    def __getitem__(self, idx):
        image = Image.open(self.images[idx]).convert('RGB')
        label = self.labels[idx]
        
        if self.transform:
            image = self.transform(image)
        
        return image, label

class Model:

    def __init__(self, dir_path, classes):

        self.dir_path = dir_path
        self.classes = classes

        

        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        self.model = models.resnet18(weights='IMAGENET1K_V1')

        self.model.fc = nn.Sequential(
        nn.Dropout(0.5),
        nn.Linear(self.model.fc.in_features, 3))

        self.model.to(self.device)

        self.transform = transforms.Compose([
            transforms.Resize((256, 256)),
            transforms.RandomCrop(224),              # Random cropping
            transforms.RandomHorizontalFlip(0.5),
            transforms.RandomRotation(15),
            transforms.ColorJitter(brightness=0.4, contrast=0.4, saturation=0.4, hue=0.1),
            transforms.RandomGrayscale(p=0.1),       # Sometimes grayscale
            transforms.ToTensor(),
            transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])

        self.train_set, self.val_set = self.setup_data()

        print("model initialized")

    def freeze_layers(self):

        for name, param in self.model.named_parameters():
            if 'layer4' in name or 'fc' in name:
                param.requires_grad = True

            else:
                param.requires_grad = False
        
        trainable = sum(p.numel() for p in self.model.parameters() if p.requires_grad)
        total = sum(p.numel() for p in self.model.parameters())
        print(f"Trainable params: {trainable:,} / {total:,}")
    

    def setup_data(self, batch_size=16):

        dataset = SimpleDataset(self.dir_path, self.classes, self.transform)
        train_ratio, test_ratio = 0.8, 0.2

        train_size = int(train_ratio * len(dataset))
        test_size = len(dataset) - train_size

        train, test, = torch.utils.data.random_split(dataset, [train_size, test_size])

        self.train_loader = DataLoader(train, batch_size=batch_size, shuffle=True)
        self.val_loader = DataLoader(test, batch_size=batch_size, shuffle=False)
        
        print(f"Train: {train_size}, Val: {test_size}")
        return self.train_loader, self.val_loader
    

    def train(self, epochs = 20):

        self.freeze_layers()
        loss_func = nn.CrossEntropyLoss()
        optimizer = torch.optim.Adam(self.model.parameters(), lr=0.0001)
        best_acc = 0

        for i in range(epochs):
            val_correct = 0
            val_total = 0
            train_correct = 0

            self.model.train()

            num_correct_pred = 0
            train_loss = 0
            train_total = 0

            for images, labels in self.train_loader:

                images = images.to(self.device)
                labels = labels.to(self.device)

                optimizer.zero_grad()

                pred_labels = self.model(images)
                loss = loss_func(pred_labels, labels)

                loss.backward()
                optimizer.step()

                train_loss += loss.item()                     
                _, predicted = torch.max(pred_labels, 1)             
                train_total += labels.size(0)                          
                train_correct += (predicted == labels).sum().item() 

            self.model.eval()
            with torch.no_grad():
                
                for images, labels in self.val_loader:

                    images, labels = images.to(self.device), labels.to(self.device)
                    

                    outputs = self.model(images)
                    

                    _, predicted = torch.max(outputs, 1)
                    val_total += labels.size(0)
                    val_correct += (predicted == labels).sum().item()
                    
            train_acc = 100 * train_correct / train_total
            val_acc = 100 * val_correct / val_total
        
            print(f'Epoch {i+1}/{epochs}:')
            print(f'  Train Acc: {train_acc:.1f}% | Val Acc: {val_acc:.1f}%')
            
            if val_acc > best_acc:
                best_acc = val_acc
                # Save the model's learned weights to disk
                torch.save(self.model.state_dict(), 'best_model.pth')
                print(f'  New best: {best_acc:.1f}%')
        
        print(f'\nTraining done! Best accuracy: {best_acc:.1f}%')

    def predict(self, image_path):

        self.model.eval()
        image = Image.open(image_path).convert('RGB')

        image = self.transform(image).unsqueeze(0).to(self.device)

        with torch.no_grad():

            outputs = self.model(image)

            _, predicted = torch.max(outputs, 1)
            probs = torch.softmax(outputs, dim=1)


        result = self.classes[predicted.item()]                    
        confidence = probs[0][predicted.item()].item()        
        
        return result, confidence


def main():

    classes = ['Safe', 'Cautious', 'Dangerous']
    data_dir = 'data'

    for folder in classes:
        os.makedirs(os.path.join(data_dir, folder), exist_ok=True)
    
    print("Put your images in:")
    print("  data/safe/       - safe distance images")
    print("  data/too_close/  - too close images") 
    print("  data/danger/     - danger images")
    print()
    
    total_images = 0
    for folder in classes:
        path = os.path.join(data_dir, folder)
        if os.path.exists(path):
            count = len([f for f in os.listdir(path) if f.endswith(('.jpg', '.jpeg', '.png'))])
            total_images += count
            print(f"{folder}: {count} images")
    
    if total_images == 0:
        print("No images found! Add some images first.")
        return
    
    # Create and train the model
    model = Model(data_dir, classes)          
    model.train(epochs=12)         
    
    print("\nModel saved as 'best_model.pth'")
    print("Test it:")
    print("result, confidence = model.predict('test.jpg')")

# Run the script
if __name__ == "__main__":
    main()