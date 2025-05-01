import numpy as np
import pickle
import sys
import json

class FingerprintDescriptorProcessor:
    def __init__(self):
        pass

    def load_features(self, feature_file):
        """Load features from file"""
        try:
            with open(feature_file, 'rb') as f:
                data = pickle.load(f)
                if not all(key in data for key in ['keypoints', 'descriptors']):
                    raise ValueError("Invalid feature file format")
                return data
        except Exception as e:
            print(f"Error loading features: {str(e)}")
            sys.exit(1)

    def process_to_circom_input(self, features1, features2, max_descriptors=10, desc_length=32):
        """Convert fingerprint features to Circom-compatible JSON with integer descriptors"""

        def process_descriptors(descriptors):
            descriptors = np.array(descriptors, dtype=np.uint8)

            # Pad or truncate descriptors
            if len(descriptors) > max_descriptors:
                descriptors = descriptors[:max_descriptors]
            elif len(descriptors) < max_descriptors:
                padding = np.zeros((max_descriptors - len(descriptors), desc_length), dtype=np.uint8)
                descriptors = np.vstack([descriptors, padding])

            # Convert each descriptor to list of integers
            processed = []
            for desc in descriptors:
                if len(desc) > desc_length:
                    desc = desc[:desc_length]
                elif len(desc) < desc_length:
                    desc = np.pad(desc, (0, desc_length - len(desc)), 'constant')

                # Each descriptor becomes a list of integers
                processed.append([int(byte) for byte in desc])

            return processed

        # Process both sets of descriptors
        query_descriptors = process_descriptors(features1['descriptors'])
        database_descriptors = process_descriptors(features2['descriptors'])

        # Create output dictionary in Circom format
        return {
            "query_descriptors": query_descriptors,
            "database_descriptors": database_descriptors
        }

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python fingerprint_processor.py features1.pkl features2.pkl")
        sys.exit(1)

    processor = FingerprintDescriptorProcessor()

    try:
        features1 = processor.load_features(sys.argv[1])
        features2 = processor.load_features(sys.argv[2])

        # Convert to Circom input format (defaults to 32 bytes per descriptor)
        input_json = processor.process_to_circom_input(features1, features2)

        # Save to file - using default=str to handle numpy types
        with open("circom_input.json", "w") as f:
            json.dump(input_json, f, indent=2, default=lambda x: x.tolist() if hasattr(x, 'tolist') else x)

        print("Circom-compatible JSON generated successfully!")
        print(f"Query descriptors: {len(input_json['query_descriptors'])}")
        print(f"Database descriptors: {len(input_json['database_descriptors'])}")
        print(f"Each descriptor has {len(input_json['query_descriptors'][0])} integers (bytes)")
    except Exception as e:
        print(f"Error: {str(e)}")
        sys.exit(1)

