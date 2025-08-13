# from image_serach import search_by_image

# search_by_image('../assets/images/demo2.jpg');


from image_serach import seed, search_by_image, search, search_flexible

def main():
    print("=== IMAGE VECTOR SEARCH TEST ===")

    # 👉 Run seed() once, comment this after seeding once
    should_seed = True  # Change to False after first run!

    if should_seed:
        print("\nSeeding the database with demo images...")
        seed()
        print("Done seeding.\n")

    # 👉 Now test search_by_image
    print("\nRunning image-to-image search...")
    search_by_image('../assets/images/demo3.jpg')

    # # 👉 Or test text-to-image search
    # print("\nRunning text-to-image search...")
    # search()

    # # 👉 Or test flexible search
    # print("\nRunning flexible search with text...")
    # search_flexible(query="a bike in front of a red brick wall")

    # print("\nRunning flexible search with image...")
    # search_flexible(image_path='../assets/images/demo2.jpg')

if __name__ == "__main__":
    main()
