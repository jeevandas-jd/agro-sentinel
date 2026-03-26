from sklearn.metrics import classification_report, confusion_matrix
import numpy as np

all_preds = []
all_labels = []

with torch.no_grad():
    for images, labels in test_loader:
        images = images.to(CONFIG['device'])
        labels = labels.to(CONFIG['device'])

        outputs = model(images)
        preds = torch.argmax(outputs, dim=1)

        all_preds.extend(preds.cpu().numpy())
        all_labels.extend(labels.cpu().numpy())
class_names = ["Non-Damaged", "Damaged"]

# Get a batch
images, labels = next(iter(test_loader))

images = images.to(CONFIG['device'])

# Forward pass
with torch.no_grad():
    outputs = model(images)
    probs = F.softmax(outputs, dim=1)   # convert logits → probabilities
    preds = torch.argmax(probs, dim=1)

# Move everything to CPU
images = images.cpu()
labels = labels.cpu()
preds = preds.cpu()
probs = probs.cpu()

# Plot
for i in range(5):
    img = images[i].permute(1, 2, 0).numpy()

    # Normalize image for display (IMPORTANT if normalized earlier)
    img = (img - img.min()) / (img.max() - img.min())

    true_label = class_names[labels[i].item()]
    pred_label = class_names[preds[i].item()]
    confidence = probs[i][preds[i]].item() * 100

    # Check correctness
    correct = (labels[i] == preds[i])

    plt.imshow(img)
    
    plt.title(
        f"Prediction: {pred_label} ({confidence:.2f}%)\n"
        f"Actual: {true_label} | {'✅ Correct' if correct else '❌ Wrong'}",
        fontsize=10
    )
    
    plt.axis('off')
    plt.show()
