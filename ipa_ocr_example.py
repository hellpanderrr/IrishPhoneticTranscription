#!/usr/bin/env python3
"""
Example script demonstrating how to use the IPA OCR tool.
"""

import os
import argparse
from ipa_model import IPAOCRProcessor

def main():
    """
    Main function to demonstrate the IPA OCR tool.
    """
    parser = argparse.ArgumentParser(description='IPA OCR Example')
    parser.add_argument('image_path', type=str, help='Path to the input image')
    parser.add_argument('--output_dir', '-o', type=str, default='ocr_results',
                        help='Directory to save the output')
    parser.add_argument('--show', '-s', action='store_true',
                        help='Show the processed image')
    parser.add_argument('--model', '-m', type=str,
                        default="ocr-special-characters-mobilenetv2.pt",
                        help='Path to the local PyTorch model file (.pt)')
    parser.add_argument('--sliding-window', '-w', action='store_true',
                        help='Use sliding window approach to extract multiple characters')
    parser.add_argument('--window-size', type=int, default=224,
                        help='Size of the sliding window (default: 224)')
    parser.add_argument('--step-size', type=int, default=112,
                        help='Step size for the sliding window (default: 112)')

    args = parser.parse_args()

    # Create output directory if it doesn't exist
    if not os.path.exists(args.output_dir):
        os.makedirs(args.output_dir)

    # Get the base filename without extension
    base_filename = os.path.splitext(os.path.basename(args.image_path))[0]
    output_path = os.path.join(args.output_dir, f"{base_filename}_ocr.txt")

    # Initialize the OCR processor
    try:
        processor = IPAOCRProcessor(model_path=args.model)
        print(f"Using model: {args.model}")
    except Exception as e:
        print(f"Error initializing the OCR processor: {e}")
        return

    print(f"Processing image: {args.image_path}")

    # Process the image
    result = processor.process_image(
        image_path=args.image_path,
        output_path=output_path,
        show_image=args.show,
        use_sliding_window=args.sliding_window
    )

    # If using sliding window with custom parameters
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
        if output_path:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(corrected_result)
        result = corrected_result

    # Print the result
    print("\nExtracted IPA Text:")
    print("-" * 50)
    print(result)
    print("-" * 50)

    print(f"\nResults saved to: {output_path}")
    print(f"Processed image saved to: {os.path.splitext(output_path)[0]}_processed.png")

if __name__ == "__main__":
    main()
