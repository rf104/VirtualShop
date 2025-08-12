from PIL import Image
from sentence_transformers import SentenceTransformer
import vecs
from matplotlib import pyplot as plt
from matplotlib import image as mpimg
import os
from typing import List, Tuple, Optional


# Local development connection string
# For production, use your Supabase project URL instead
DB_CONNECTION = "postgresql://postgres.wnaqfhqvghulydvnpcsw:01769041694@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres"

def seed():
    # create vector store client
    vx = vecs.create_client(DB_CONNECTION)

    # create a collection of vectors with 3 dimensions
    images = vx.get_or_create_collection(name="image_vectors", dimension=512)

    # Load CLIP model
    model = SentenceTransformer('clip-ViT-B-32')

    # Encode an image:
    img_emb1 = model.encode(Image.open('../assets/images/demo1.jpg'))
    img_emb2 = model.encode(Image.open('../assets/images/demo2.jpg'))
    img_emb3 = model.encode(Image.open('../assets/images/demo3.jpg'))
    img_emb4 = model.encode(Image.open('../assets/images/demo4.jpg'))

    # add records to the *images* collection
    images.upsert(
        records=[
            (
                "demo1.jpg",        # the vector's identifier
                img_emb1,          # the vector. list or np.array
                {"type": "jpg"}   # associated  metadata
            ), (
                "demo2.jpg",
                img_emb2,
                {"type": "jpg"}
            ), (
                "demo3.jpg",
                img_emb3,
                {"type": "jpg"}
            ), (
                "demo4.jpg",
                img_emb4,
                {"type": "jpg"}
            )
        ]
    )
    print("Inserted images")

    # index the collection for fast search performance
    images.create_index()
    print("Created index")



def search():
    # create vector store client
    vx = vecs.create_client(DB_CONNECTION)
    images = vx.get_or_create_collection(name="image_vectors", dimension=512)

    # Load CLIP model
    model = SentenceTransformer('clip-ViT-B-32')
    # Encode text query
    query_string = "a bike in front of a red brick wall"
    text_emb = model.encode(query_string)

    # query the collection filtering metadata for "type" = "jpg"
    results = images.query(
        data=text_emb,                      # required
        limit=1,                            # number of records to return
        filters={"type": {"$eq": "jpg"}},   # metadata filters
    )
    
    if results:
        result = results[0]
        print(f"Found result: {result}")
        # Extract the filename from the result (assuming result is a tuple/list)
        filename = result[0] if isinstance(result, (tuple, list)) else str(result)
        print(f"Displaying image: {filename}")
        plt.title(f"Search result: {filename}")
        image_path = f'../assets/images/{filename}'
        if os.path.exists(image_path):
            image = mpimg.imread(image_path)
            plt.imshow(image)
            plt.show()
        else:
            print(f"Image file not found: {image_path}")
    else:
        print("No results found for the search query.")


def search_by_image(image_path: str, limit: int = 3) -> List[Tuple]:
    """
    Search for similar images using an input image
    
    Args:
        image_path: Path to the query image
        limit: Number of results to return
        
    Returns:
        List of similar images with their metadata
    """
    # create vector store client
    vx = vecs.create_client(DB_CONNECTION)
    images = vx.get_or_create_collection(name="image_vectors", dimension=512)

    # Load CLIP model
    model = SentenceTransformer('clip-ViT-B-32')
    
    # Encode the query image
    query_img = Image.open(image_path)
    # query_img = Image.open('../assets/images/demo1.jpg')
    query_emb = model.encode(query_img)

    # query the collection
    results = images.query(
        data=query_emb,                     # required
        limit=limit,                        # number of records to return
        filters={"type": {"$eq": "jpg"}},   # metadata filters
    )
    
    if results:
        print(f"Found {len(results)} similar images:")
        for i, result in enumerate(results):
            filename = result[0] if isinstance(result, (tuple, list)) else str(result)
            print(f"{i+1}. {filename}")
            
            # Display images in a subplot
            plt.subplot(1, len(results), i+1)
            image_path_result = f'../assets/images/{filename}'
            if os.path.exists(image_path_result):
                image = mpimg.imread(image_path_result)
                plt.imshow(image)
                plt.title(f"{filename}")
                plt.axis('off')
            else:
                print(f"Image file not found: {image_path_result}")
        
        plt.tight_layout()
        plt.show()
        return results
    else:
        print("No similar images found.")
        return []


def search_flexible(query: str = None, image_path: str = None, limit: int = 3) -> List[Tuple]:
    """
    Flexible search function that can handle both text and image queries
    
    Args:
        query: Text query for text-to-image search
        image_path: Path to image for image-to-image search  
        limit: Number of results to return
        
    Returns:
        List of search results
    """
    if not query and not image_path:
        raise ValueError("Either query text or image_path must be provided")
    
    # create vector store client
    vx = vecs.create_client(DB_CONNECTION)
    images = vx.get_or_create_collection(name="image_vectors", dimension=512)

    # Load CLIP model
    model = SentenceTransformer('clip-ViT-B-32')
    
    # Generate embedding based on input type
    if image_path:
        print(f"Searching by image: {image_path}")
        query_img = Image.open(image_path)
        search_emb = model.encode(query_img)
    else:
        print(f"Searching by text: {query}")
        search_emb = model.encode(query)

    # query the collection
    results = images.query(
        data=search_emb,                    # required
        limit=limit,                        # number of records to return
        filters={"type": {"$eq": "jpg"}},   # metadata filters
    )
    
    if results:
        print(f"Found {len(results)} results:")
        for i, result in enumerate(results):
            filename = result[0] if isinstance(result, (tuple, list)) else str(result)
            print(f"{i+1}. {filename}")
            
            # Display images in a subplot
            plt.subplot(1, len(results), i+1)
            image_path_result = f'../assets/images/{filename}'
            if os.path.exists(image_path_result):
                image = mpimg.imread(image_path_result)
                plt.imshow(image)
                plt.title(f"{filename}")
                plt.axis('off')
            else:
                print(f"Image file not found: {image_path_result}")
        
        plt.tight_layout()
        plt.show()
        return results
    else:
        print("No results found.")
        return []