# IPA OCR Tool

This tool performs Optical Character Recognition (OCR) on images containing IPA (International Phonetic Alphabet) characters. It uses a specialized PyTorch model to accurately extract and recognize IPA text from images.

## Features

- Image preprocessing for optimal OCR results
- Support for IPA (International Phonetic Alphabet) characters
- Correction of common OCR errors in IPA text
- PyTorch model-based OCR for IPA characters
- Visualization of original and processed images
- Saving of extracted text and processed images

## Requirements

- Python 3.6+
- PyTorch
- OpenCV (cv2)
- Pillow (PIL)
- NumPy
- Matplotlib

## Installation

1. Install Python dependencies:

```bash
pip install torch opencv-python pillow numpy matplotlib
```

2. Ensure you have the PyTorch model file:

   - Make sure the file `ocr-special-characters-mobilenetv2.pt` is in your working directory
   - This is a pre-trained PyTorch model for OCR with special characters

## Usage

### Command Line Interface

```bash
python ipa_model.py image_path [options]
```

#### Arguments:

- `image_path`: Path to the input image containing IPA text

#### Options:

- `--output`, `-o`: Path to save the output text
- `--model`, `-m`: Path to the local PyTorch model file (default: "ocr-special-characters-mobilenetv2.pt")
- `--show`, `-s`: Show the processed image
- `--cpu`: Force CPU usage even if GPU is available

### Python API

```python
from ipa_model import IPAOCRProcessor

# Initialize the processor
processor = IPAOCRProcessor(
    model_path="ocr-special-characters-mobilenetv2.pt",  # Path to your local PyTorch model file
    use_gpu=True
)

# Process an image
result = processor.process_image(
    image_path="path/to/your/image.jpg",
    output_path="path/to/save/result.txt",
    show_image=True
)

# Print the extracted text
print(result)
```

## Examples

### Basic Usage

```bash
python ipa_model.py sample_ipa_text.jpg
```

### Save Output to File

```bash
python ipa_model.py sample_ipa_text.jpg -o extracted_text.txt
```

### Use a Different Model File

```bash
python ipa_model.py sample_ipa_text.jpg --model custom_model.pt
```

### Show Processed Image

```bash
python ipa_model.py sample_ipa_text.jpg -s
```

## Customizing IPA Character Mapping

You can extend or modify the IPA character mapping in the `IPAOCRProcessor.IPA_CHAR_MAP` dictionary to improve recognition for specific IPA characters or to correct common OCR errors for your particular use case.

## Troubleshooting

1. **Tesseract not found**: Ensure Tesseract is installed and the path is correctly set in your environment variables.

2. **Missing IPA language support**: Make sure you've downloaded and installed the IPA language data file in the correct Tesseract tessdata directory.

3. **Model loading errors**: Check that you have an internet connection when loading the model for the first time, as it needs to download the model files.

4. **Poor OCR results**: Try adjusting the image preprocessing parameters in the `preprocess_image` method to better suit your specific images.

## License

This tool is provided under the MIT License.

## Acknowledgments

- The OCR model is based on the "ocr-special-characters-classification-mobilenetv2" model from Hugging Face.
- Tesseract OCR is developed by Google and the open-source community.
- IPA language support for Tesseract is provided by the Shreeshrii/tessdata_ipa project.
