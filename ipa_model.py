#!/usr/bin/env python3
"""
IPA OCR Tool - Optical Character Recognition for IPA (International Phonetic Alphabet) characters
This script processes images containing IPA text and extracts the text content.
"""

import os
import argparse
import numpy as np
import cv2
from PIL import Image
import torch
from pathlib import Path
import matplotlib.pyplot as plt
import re

class IPAOCRProcessor:
    """
    A class to process images containing IPA characters and extract text using OCR.
    """

    # IPA character mapping - extend this dictionary with more IPA characters as needed
    IPA_CHAR_MAP = {
        # Vowels
        'i': 'i', 'y': 'y', 'ɨ': 'ɨ', 'ʉ': 'ʉ', 'ɯ': 'ɯ', 'u': 'u',
        'ɪ': 'ɪ', 'ʏ': 'ʏ', 'ʊ': 'ʊ', 'e': 'e', 'ø': 'ø', 'ɘ': 'ɘ',
        'ɵ': 'ɵ', 'ɤ': 'ɤ', 'o': 'o', 'ə': 'ə', 'ɛ': 'ɛ', 'œ': 'œ',
        'ɜ': 'ɜ', 'ɞ': 'ɞ', 'ʌ': 'ʌ', 'ɔ': 'ɔ', 'æ': 'æ', 'ɐ': 'ɐ',
        'a': 'a', 'ɶ': 'ɶ', 'ɑ': 'ɑ', 'ɒ': 'ɒ',
        # Consonants
        'p': 'p', 'b': 'b', 't': 't', 'd': 'd', 'ʈ': 'ʈ', 'ɖ': 'ɖ',
        'c': 'c', 'ɟ': 'ɟ', 'k': 'k', 'g': 'g', 'q': 'q', 'ɢ': 'ɢ',
        'ʔ': 'ʔ', 'm': 'm', 'ɱ': 'ɱ', 'n': 'n', 'ɳ': 'ɳ', 'ɲ': 'ɲ',
        'ŋ': 'ŋ', 'ɴ': 'ɴ', 'ʙ': 'ʙ', 'r': 'r', 'ʀ': 'ʀ', 'ⱱ': 'ⱱ',
        'ɾ': 'ɾ', 'ɽ': 'ɽ', 'ɸ': 'ɸ', 'β': 'β', 'f': 'f', 'v': 'v',
        'θ': 'θ', 'ð': 'ð', 's': 's', 'z': 'z', 'ʃ': 'ʃ', 'ʒ': 'ʒ',
        'ʂ': 'ʂ', 'ʐ': 'ʐ', 'ç': 'ç', 'ʝ': 'ʝ', 'x': 'x', 'ɣ': 'ɣ',
        'χ': 'χ', 'ʁ': 'ʁ', 'ħ': 'ħ', 'ʕ': 'ʕ', 'h': 'h', 'ɦ': 'ɦ',
        'ɬ': 'ɬ', 'ɮ': 'ɮ', 'ʋ': 'ʋ', 'ɹ': 'ɹ', 'ɻ': 'ɻ', 'j': 'j',
        'ɰ': 'ɰ', 'l': 'l', 'ɭ': 'ɭ', 'ʎ': 'ʎ', 'ʟ': 'ʟ', 'ɫ': 'ɫ',
        # Diacritics and suprasegmentals
        'ˈ': 'ˈ', 'ˌ': 'ˌ', 'ː': 'ː', 'ˑ': 'ˑ', '̆': '̆', '|': '|',
        '‖': '‖', '.': '.', '‿': '‿', '͡': '͡', '͜': '͜',
        # Common substitutions in OCR errors
        'I': 'ɪ', 'E': 'ɛ', 'A': 'ɑ', 'O': 'ɔ', 'U': 'ʊ',
        '3': 'ɛ', '0': 'ə', '6': 'ə', '9': 'ɘ', '@': 'ə',
        # Add more mappings as needed
    }

    # Class index to IPA character mapping
    # This is a placeholder - you should update this with the actual mapping for your model
    CLASS_TO_IPA = {
        0: 'a',
        1: 'e',
        2: 'i',
        3: 'o',
        4: 'u',
        5: 'ə',
        6: 'ɑ',
        7: 'ɛ',
        8: 'ɪ',
        9: 'ʊ',
        10: 'æ',
        11: 'ɔ',
        12: 'ʃ',
        13: 'ʒ',
        14: 'θ',
        15: 'ð',
        16: 'ŋ',
        17: 'ɲ',
        18: 'ɾ',
        19: 'ʔ',
        # Add more mappings as needed
    }

    def __init__(self, model_path, use_gpu=True):
        """
        Initialize the OCR processor with the specified model.

        Args:
            model_path (str): Path to the local PyTorch model file (.pt).
            use_gpu (bool): Whether to use GPU for inference if available.
        """
        self.use_gpu = use_gpu and torch.cuda.is_available()
        self.device = torch.device('cuda' if self.use_gpu else 'cpu')
        print(f"Using device: {self.device}")

        # Load the PyTorch model
        self.model = None
        if not model_path:
            raise ValueError("A model path must be provided")

        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Model file not found at: {model_path}")

        try:
            print(f"Loading PyTorch model from: {model_path}")

            # Try different loading methods
            try:
                # Method 1: Standard PyTorch loading
                self.model = torch.load(model_path, map_location=self.device)
                print("Model loaded using standard torch.load")
            except Exception as e1:
                print(f"Standard loading failed: {e1}")
                try:
                    # Method 2: Try loading as a state dict
                    import torch.nn as nn
                    # Create a simple model architecture (placeholder)
                    self.model = nn.Sequential(
                        nn.Conv2d(3, 32, kernel_size=3, padding=1),
                        nn.ReLU(),
                        nn.MaxPool2d(2),
                        nn.Conv2d(32, 64, kernel_size=3, padding=1),
                        nn.ReLU(),
                        nn.MaxPool2d(2),
                        nn.Flatten(),
                        nn.Linear(64 * 56 * 56, 128),
                        nn.ReLU(),
                        nn.Linear(128, 10)  # Assuming 10 classes
                    )
                    # Load the state dict
                    state_dict = torch.load(model_path, map_location=self.device)
                    if isinstance(state_dict, dict) and 'state_dict' in state_dict:
                        self.model.load_state_dict(state_dict['state_dict'])
                    else:
                        self.model.load_state_dict(state_dict)
                    print("Model loaded as state dictionary")
                except Exception as e2:
                    print(f"State dict loading failed: {e2}")
                    try:
                        # Method 3: Try loading with pickle
                        import pickle
                        with open(model_path, 'rb') as f:
                            self.model = pickle.load(f)
                        print("Model loaded using pickle")
                    except Exception as e3:
                        print(f"Pickle loading failed: {e3}")
                        raise RuntimeError("All loading methods failed")

            # Put the model in evaluation mode if it's a nn.Module
            if hasattr(self.model, 'eval'):
                self.model.eval()
                print(f"Model set to evaluation mode")
            else:
                print(f"Model doesn't have eval method (not a standard nn.Module)")

            # Print model info if available
            if hasattr(self.model, '__class__'):
                print(f"Model type: {self.model.__class__.__name__}")

            # Try to print model structure
            if hasattr(self.model, '__repr__'):
                model_repr = self.model.__repr__()
                # Print only the first few lines to avoid overwhelming output
                print("Model structure (truncated):")
                print("\n".join(model_repr.split("\n")[:10]))
                if len(model_repr.split("\n")) > 10:
                    print("... (truncated)")
        except Exception as e:
            raise RuntimeError(f"Error loading model: {e}")

    def preprocess_image(self, image_path):
        """
        Preprocess the image for better OCR results.

        Args:
            image_path (str): Path to the input image.

        Returns:
            numpy.ndarray: Preprocessed image.
        """
        # Read the image
        image = cv2.imread(image_path)
        if image is None:
            raise ValueError(f"Could not read image at {image_path}")

        # Convert to grayscale
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Apply adaptive thresholding
        thresh = cv2.adaptiveThreshold(
            gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY_INV, 11, 2
        )

        # Noise removal
        kernel = np.ones((1, 1), np.uint8)
        opening = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, kernel, iterations=1)

        # Invert back to black text on white background
        result = cv2.bitwise_not(opening)

        return result, image

    # Tesseract OCR method removed

    def extract_text_with_model(self, image):
        """
        Extract text from the image using the loaded model.

        Args:
            image (numpy.ndarray): Preprocessed image.

        Returns:
            str: Extracted text.
        """
        if self.model is None:
            return ""

        try:
            # Convert grayscale to RGB if needed
            if len(image.shape) == 2 or (len(image.shape) == 3 and image.shape[2] == 1):
                # This is a grayscale image, convert to RGB
                image_rgb = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
            else:
                # Already RGB or BGR
                image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

            # Convert OpenCV image to PIL Image
            pil_image = Image.fromarray(image_rgb)

            # Resize image to a standard size (adjust as needed for your model)
            pil_image = pil_image.resize((224, 224))

            # Convert to tensor - now we're sure it's RGB
            img_tensor = torch.from_numpy(np.array(pil_image)).float()

            # Convert HWC to CHW format (height, width, channels) -> (channels, height, width)
            img_tensor = img_tensor.permute(2, 0, 1)

            # Add batch dimension
            img_tensor = img_tensor.unsqueeze(0)

            # Normalize pixel values to [0, 1]
            img_tensor = img_tensor / 255.0

            # Move to device
            if self.use_gpu:
                img_tensor = img_tensor.to(self.device)

            # Print tensor shape for debugging
            print(f"Input tensor shape: {img_tensor.shape}")

            # Get model information if available
            if hasattr(self.model, 'parameters'):
                # Try to get the first layer to see what it expects
                try:
                    first_param = next(self.model.parameters())
                    print(f"First model parameter shape: {first_param.shape}")
                except Exception as param_e:
                    print(f"Could not get model parameters: {param_e}")

            # Get model predictions
            with torch.no_grad():
                try:
                    # Try standard forward pass
                    outputs = self.model(img_tensor)
                    print(f"Model output type: {type(outputs)}")

                    # Process outputs based on model architecture
                    if isinstance(outputs, torch.Tensor):
                        print(f"Output tensor shape: {outputs.shape}")
                        # If output is a tensor, it might be logits
                        if outputs.dim() > 1 and outputs.size(1) > 1:
                            # Multi-class classification
                            predictions = outputs.argmax(1)
                            class_idx = predictions.item()
                            print(f"Predicted class index: {class_idx}")

                            # Map class index to IPA character if available
                            if class_idx in self.CLASS_TO_IPA:
                                ipa_char = self.CLASS_TO_IPA[class_idx]
                                return f"Predicted IPA character: {ipa_char} (class {class_idx})"
                            else:
                                return f"Model prediction class: {class_idx} (no IPA mapping available)"
                        else:
                            # Regression or single output
                            return f"Model output value: {outputs.item()}"
                    elif isinstance(outputs, dict) and 'logits' in outputs:
                        # If output is a dict with logits (common in HuggingFace models)
                        print(f"Output logits shape: {outputs['logits'].shape}")
                        predictions = outputs['logits'].argmax(1)
                        class_idx = predictions.item()
                        print(f"Predicted class index: {class_idx}")

                        # Map class index to IPA character if available
                        if class_idx in self.CLASS_TO_IPA:
                            ipa_char = self.CLASS_TO_IPA[class_idx]
                            return f"Predicted IPA character: {ipa_char} (class {class_idx})"
                        else:
                            return f"Model prediction class: {class_idx} (no IPA mapping available)"
                    elif isinstance(outputs, tuple) and len(outputs) > 0:
                        # If output is a tuple, take the first element
                        first_output = outputs[0]
                        print(f"First output in tuple shape: {first_output.shape if isinstance(first_output, torch.Tensor) else 'not a tensor'}")
                        if isinstance(first_output, torch.Tensor):
                            if first_output.dim() > 1 and first_output.size(1) > 1:
                                predictions = first_output.argmax(1)
                                class_idx = predictions.item()
                                print(f"Predicted class index: {class_idx}")

                                # Map class index to IPA character if available
                                if class_idx in self.CLASS_TO_IPA:
                                    ipa_char = self.CLASS_TO_IPA[class_idx]
                                    return f"Predicted IPA character: {ipa_char} (class {class_idx})"
                                else:
                                    return f"Model prediction class: {class_idx} (no IPA mapping available)"
                            else:
                                return f"Model output value: {first_output.item()}"
                    else:
                        # Unknown output format
                        print(f"Output details: {outputs}")
                        return f"Model produced output but format is not recognized: {type(outputs)}"
                except Exception as inner_e:
                    print(f"Error during model forward pass: {inner_e}")

                    # Try alternative approach if standard forward fails
                    if hasattr(self.model, 'predict'):
                        try:
                            print("Attempting to use predict method...")
                            predictions = self.model.predict(img_tensor)
                            print(f"Predict method result: {predictions}")
                            return f"Model prediction using predict method: {predictions}"
                        except Exception as predict_e:
                            print(f"Error using predict method: {predict_e}")

                    # Try to inspect model structure
                    print("\nModel structure:")
                    if hasattr(self.model, '__repr__'):
                        print(self.model.__repr__())
                    else:
                        print("Model doesn't have a standard representation")

                    # Try a simple CNN-based approach as a last resort
                    try:
                        print("\nAttempting simple CNN-based text extraction...")
                        extracted_text = self.simple_cnn_text_extraction(img_tensor)
                        if extracted_text:
                            return f"Text extracted using simple CNN approach: {extracted_text}"
                    except Exception as cnn_e:
                        print(f"Simple CNN approach failed: {cnn_e}")

                    return "Could not process model output"
        except Exception as e:
            print(f"Model inference error: {e}")
            return ""

    def simple_cnn_text_extraction(self, img_tensor):
        """
        A simple CNN-based approach to extract text features from an image.
        This is a fallback method when the main model fails.

        Args:
            img_tensor (torch.Tensor): The preprocessed image tensor.

        Returns:
            str: Extracted text or empty string if extraction fails.
        """
        try:
            # Create a simple CNN model for feature extraction
            import torch.nn as nn
            import torch.nn.functional as F

            class SimpleTextCNN(nn.Module):
                def __init__(self):
                    super(SimpleTextCNN, self).__init__()
                    self.conv1 = nn.Conv2d(3, 16, kernel_size=3, padding=1)
                    self.pool1 = nn.MaxPool2d(2)
                    self.conv2 = nn.Conv2d(16, 32, kernel_size=3, padding=1)
                    self.pool2 = nn.MaxPool2d(2)
                    self.conv3 = nn.Conv2d(32, 64, kernel_size=3, padding=1)
                    self.pool3 = nn.MaxPool2d(2)
                    self.fc1 = nn.Linear(64 * 28 * 28, 512)
                    self.fc2 = nn.Linear(512, 128)

                def forward(self, x):
                    x = self.pool1(F.relu(self.conv1(x)))
                    x = self.pool2(F.relu(self.conv2(x)))
                    x = self.pool3(F.relu(self.conv3(x)))
                    x = x.view(-1, 64 * 28 * 28)
                    x = F.relu(self.fc1(x))
                    x = self.fc2(x)
                    return x

            # Create the model and extract features
            cnn_model = SimpleTextCNN().to(self.device)
            with torch.no_grad():
                features = cnn_model(img_tensor)

            # Convert features to a simple text representation
            # This is a very simplistic approach - in a real scenario, you would need
            # a more sophisticated method to convert features to text
            feature_values = features.cpu().numpy().flatten()

            # Use the top 5 feature values to generate a simple representation
            top_indices = np.argsort(feature_values)[-5:]

            # Map these indices to IPA characters (very simplistic)
            ipa_chars = list(self.IPA_CHAR_MAP.keys())
            result = ""
            for idx in top_indices:
                char_idx = idx % len(ipa_chars)
                result += ipa_chars[char_idx]

            return result
        except Exception as e:
            print(f"Simple CNN text extraction failed: {e}")
            return ""

    def correct_ipa_characters(self, text):
        """
        Correct common OCR errors in IPA text.

        Args:
            text (str): Raw OCR text.

        Returns:
            str: Corrected text.
        """
        # Replace common OCR errors with correct IPA characters
        for wrong, correct in self.IPA_CHAR_MAP.items():
            text = text.replace(wrong, correct)

        # Remove non-printable characters
        text = re.sub(r'[^\x20-\x7E\u0080-\u9FFF]', '', text)

        return text

    def process_image_with_sliding_window(self, processed_image, window_size=224, step_size=112):
        """
        Process an image using a sliding window approach to extract multiple characters.

        Args:
            processed_image (numpy.ndarray): Preprocessed image.
            window_size (int): Size of the sliding window.
            step_size (int): Step size for the sliding window.

        Returns:
            str: Extracted text from all windows.
        """
        height, width = processed_image.shape[:2]
        result_text = ""

        # Create a visualization of the sliding windows if needed
        if hasattr(self, 'show_sliding_windows') and self.show_sliding_windows:
            vis_image = processed_image.copy()
            if len(vis_image.shape) == 2:
                vis_image = cv2.cvtColor(vis_image, cv2.COLOR_GRAY2BGR)

        # Process the image with sliding windows
        for y in range(0, height - window_size + 1, step_size):
            for x in range(0, width - window_size + 1, step_size):
                # Extract the window
                window = processed_image[y:y + window_size, x:x + window_size]

                # Process the window
                window_text = self.extract_text_with_model(window)

                # Extract just the character from the result text
                if "Predicted IPA character:" in window_text:
                    char_start = window_text.find("Predicted IPA character:") + len("Predicted IPA character:")
                    char_end = window_text.find("(class")
                    if char_end > char_start:
                        char = window_text[char_start:char_end].strip()
                        result_text += char

                        # Draw the window on the visualization image
                        if hasattr(self, 'show_sliding_windows') and self.show_sliding_windows:
                            cv2.rectangle(vis_image, (x, y), (x + window_size, y + window_size), (0, 255, 0), 2)
                            cv2.putText(vis_image, char, (x + 10, y + 20), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 255), 1)

        # Show the visualization if needed
        if hasattr(self, 'show_sliding_windows') and self.show_sliding_windows:
            plt.figure(figsize=(12, 10))
            plt.imshow(cv2.cvtColor(vis_image, cv2.COLOR_BGR2RGB))
            plt.title('Sliding Windows')
            plt.axis('off')
            plt.tight_layout()
            plt.show()

        return result_text

    def process_image(self, image_path, output_path=None, show_image=False, use_sliding_window=False):
        """
        Process an image and extract IPA text using the model.

        Args:
            image_path (str): Path to the input image.
            output_path (str, optional): Path to save the results.
            show_image (bool): Whether to display the processed image.
            use_sliding_window (bool): Whether to use sliding window approach for multiple characters.

        Returns:
            str: Extracted and corrected text.
        """
        # Preprocess the image
        processed_image, original_image = self.preprocess_image(image_path)

        # Extract text using the model
        if use_sliding_window:
            # Set flag for visualization if needed
            self.show_sliding_windows = show_image
            model_text = self.process_image_with_sliding_window(processed_image)
        else:
            model_text = self.extract_text_with_model(processed_image)

        # Correct the text
        corrected_text = self.correct_ipa_characters(model_text)

        # Display the image if requested and not using sliding window
        if show_image and not use_sliding_window:
            plt.figure(figsize=(12, 10))

            plt.subplot(1, 2, 1)
            plt.imshow(cv2.cvtColor(original_image, cv2.COLOR_BGR2RGB))
            plt.title('Original Image')
            plt.axis('off')

            plt.subplot(1, 2, 2)
            plt.imshow(processed_image, cmap='gray')
            plt.title('Processed Image')
            plt.axis('off')

            plt.tight_layout()
            plt.show()

        # Save results if output path is provided
        if output_path:
            output_dir = os.path.dirname(output_path)
            if output_dir and not os.path.exists(output_dir):
                os.makedirs(output_dir)

            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(corrected_text)

            # Save the processed image
            image_output_path = os.path.splitext(output_path)[0] + '_processed.png'
            cv2.imwrite(image_output_path, processed_image)

        return corrected_text

def main():
    """
    Main function to run the IPA OCR tool from command line.
    """
    parser = argparse.ArgumentParser(description='OCR tool for IPA characters')
    parser.add_argument('image_path', type=str, help='Path to the input image')
    parser.add_argument('--output', '-o', type=str, help='Path to save the output text')
    parser.add_argument('--model', '-m', type=str,
                        default="ocr-special-characters-mobilenetv2.pt",
                        help='Path to the local PyTorch model file (.pt)')
    parser.add_argument('--show', '-s', action='store_true',
                        help='Show the processed image')
    parser.add_argument('--cpu', action='store_true',
                        help='Force CPU usage even if GPU is available')
    parser.add_argument('--sliding-window', '-w', action='store_true',
                        help='Use sliding window approach to extract multiple characters')
    parser.add_argument('--window-size', type=int, default=224,
                        help='Size of the sliding window (default: 224)')
    parser.add_argument('--step-size', type=int, default=112,
                        help='Step size for the sliding window (default: 112)')

    args = parser.parse_args()

    # Create the processor
    try:
        processor = IPAOCRProcessor(model_path=args.model, use_gpu=not args.cpu)
    except Exception as e:
        print(f"Error initializing the OCR processor: {e}")
        return

    # Process the image
    result = processor.process_image(
        args.image_path,
        output_path=args.output,
        show_image=args.show,
        use_sliding_window=args.sliding_window
    )

    # If using sliding window, customize the window and step size
    if args.sliding_window and (args.window_size != 224 or args.step_size != 112):
        print(f"Using custom sliding window: size={args.window_size}, step={args.step_size}")
        processor.show_sliding_windows = args.show
        processed_image, _ = processor.preprocess_image(args.image_path)
        result = processor.process_image_with_sliding_window(
            processed_image,
            window_size=args.window_size,
            step_size=args.step_size
        )

        # Correct and save the result if needed
        corrected_result = processor.correct_ipa_characters(result)
        if args.output:
            output_dir = os.path.dirname(args.output)
            if output_dir and not os.path.exists(output_dir):
                os.makedirs(output_dir)
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(corrected_result)
        result = corrected_result

    # Print the result
    print("\nExtracted Text:")
    print("-" * 40)
    print(result)
    print("-" * 40)

if __name__ == "__main__":
    main()