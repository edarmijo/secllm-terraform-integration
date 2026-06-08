import os
import json
import numpy as np
from openai import OpenAI
from sklearn.metrics.pairwise import cosine_similarity
from collections import defaultdict

# Initialize the OPENAI API
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
# Configure OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)  # Replace with your API key

# Path to the folder containing files
folder = '../glitch-datasets/chef/oracle-dataset'

# Function to get embeddings from OpenAI
def get_embedding(text, model="text-embedding-3-small"):
    """Gets text embedding using OpenAI model."""
    try:
        text = text.replace("\n", " ").strip()
        response = client.embeddings.create(input=[text], model=model)
        return response.data[0].embedding
    except Exception as e:
        print(f"Error calculating embedding: {e}")
        return None

# Function to calculate cosine similarity
def calculate_cosine_similarity(embedding1, embedding2):
    """Calculates cosine similarity between two embeddings."""
    if embedding1 is None or embedding2 is None:
        return 0.0
    
    # Convert to numpy arrays and reshape for sklearn
    emb1 = np.array(embedding1).reshape(1, -1)
    emb2 = np.array(embedding2).reshape(1, -1)
    
    return cosine_similarity(emb1, emb2)[0][0]

# Data structure to store files with their embeddings and ratings
files_data = []
categories = defaultdict(list)

# Similarity threshold
similarity_threshold = 0.85

print("Loading and analyzing files...")
print("=" * 50)

# Loop through files in the folder
for root, dirs, files in os.walk(folder):
    for file_name in files:
        if file_name.endswith(('.rb', '.py', '.txt')):  # Filter for specific extensions
            file_path = os.path.join(root, file_name)
            
            try:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    content = f.read().strip()
                    
                    if len(content) > 10:  # Ignore files that are too small
                        # Simulate a rating (in a real case, this would come from expert validation phase)
                        # For this example, we use file length as a proxy for rating
                        simulated_rating = len(content) % 100
                        
                        # Determine category (in this example we use the parent folder)
                        category = os.path.basename(root) if root != folder else "root"
                        
                        print(f"Processing: {file_name} (Rating: {simulated_rating})")
                        
                        # Get embedding
                        embedding = get_embedding(content)
                        
                        if embedding is not None:
                            file_info = {
                                'name': file_name,
                                'path': file_path,
                                'content': content,
                                'embedding': embedding,
                                'rating': simulated_rating,
                                'category': category
                            }
                            
                            files_data.append(file_info)
                            categories[category].append(file_info)
                            
            except Exception as e:
                print(f"Error processing {file_name}: {e}")

print(f"\nTotal files processed: {len(files_data)}")
print("=" * 50)

# Redundancy elimination by category
selected_files = []
eliminated_files = []

for category, category_files in categories.items():
    print(f"\nProcessing category: {category} ({len(category_files)} files)")
    
    # Sort by descending rating
    category_files.sort(key=lambda x: x['rating'], reverse=True)
    
    category_selected = []
    
    for current_file in category_files:
        # Check similarity with already selected files in this category
        is_redundant = False
        
        for selected_file in category_selected:
            similarity = calculate_cosine_similarity(
                current_file['embedding'], 
                selected_file['embedding']
            )
            
            if similarity >= similarity_threshold:
                print(f"  ELIMINATED: {current_file['name']} (similarity: {similarity:.3f} with {selected_file['name']})")
                eliminated_files.append({
                    'file': current_file['name'],
                    'similar_to': selected_file['name'],
                    'similarity': similarity,
                    'category': category
                })
                is_redundant = True
                break
        
        if not is_redundant:
            category_selected.append(current_file)
            selected_files.append(current_file)
            print(f"  KEPT: {current_file['name']} (Rating: {current_file['rating']})")

# Final statistics
print("\n" + "=" * 50)
print("FINAL STATISTICS")
print("=" * 50)
print(f"Original files: {len(files_data)}")
print(f"Kept files: {len(selected_files)}")
print(f"Eliminated files: {len(eliminated_files)}")
print(f"Reduction percentage: {(len(eliminated_files)/len(files_data)*100):.1f}%")

# Statistics by category
print(f"\nSTATISTICS BY CATEGORY:")
for category in categories.keys():
    original = len(categories[category])
    kept = len([f for f in selected_files if f['category'] == category])
    print(f"  {category}: {kept}/{original} kept")

# Save results
with open('selected_files.json', 'w', encoding='utf-8') as f:
    # Remove embeddings for saving (they are too large)
    files_for_saving = []
    for file_info in selected_files:
        file_copy = file_info.copy()
        del file_copy['embedding']  # Remove embedding to save space
        files_for_saving.append(file_copy)
    
    json.dump(files_for_saving, f, indent=2, ensure_ascii=False)

with open('eliminated_files.json', 'w', encoding='utf-8') as f:
    json.dump(eliminated_files, f, indent=2, ensure_ascii=False)

print(f"\nResults saved in:")
print(f"  - selected_files.json ({len(selected_files)} files)")
print(f"  - eliminated_files.json ({len(eliminated_files)} files)")