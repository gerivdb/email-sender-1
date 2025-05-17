#!/usr/bin/env python
# -*- coding: utf-8 -*-

from qdrant_client import QdrantClient
import sys

def main():
    try:
        # Connexion à Qdrant
        client = QdrantClient(host='localhost', port=6333)
        
        # Récupérer toutes les collections
        collections = client.get_collections().collections
        collection_names = [c.name for c in collections]
        
        print("Collections Qdrant existantes:")
        for name in collection_names:
            print(f"- {name}")
        
        # Identifier les collections de roadmap
        roadmap_collections = [c for c in collection_names if c.startswith('roadmap_')]
        
        print("\nCollections de roadmap:")
        for name in roadmap_collections:
            print(f"- {name}")
        
        # Vérifier si la collection principale existe
        main_collection = 'roadmap_tasks'
        if main_collection in collection_names:
            print(f"\nInformations sur la collection principale {main_collection}:")
            info = client.get_collection(main_collection)
            print(f"Nombre de vecteurs: {info.vectors_count}")
            print(f"Dimension des vecteurs: {info.config.params.vectors.size}")
            print(f"Distance: {info.config.params.vectors.distance}")
            
            # Récupérer quelques points pour analyse
            if info.vectors_count > 0:
                print("\nÉchantillon de points:")
                scroll_result = client.scroll(
                    collection_name=main_collection,
                    limit=5,
                    with_payload=True,
                    with_vectors=False
                )
                
                points = scroll_result[0]
                for i, point in enumerate(points):
                    print(f"\nPoint {i+1}:")
                    print(f"  ID: {point.id}")
                    print(f"  Payload: {point.payload}")
        else:
            # Utiliser la première collection de roadmap comme alternative
            if roadmap_collections:
                alt_collection = roadmap_collections[0]
                print(f"\nCollection principale non trouvée. Utilisation de {alt_collection} comme alternative:")
                info = client.get_collection(alt_collection)
                print(f"Nombre de vecteurs: {info.vectors_count}")
                print(f"Dimension des vecteurs: {info.config.params.vectors.size}")
                print(f"Distance: {info.config.params.vectors.distance}")
                
                # Récupérer quelques points pour analyse
                if info.vectors_count > 0:
                    print("\nÉchantillon de points:")
                    scroll_result = client.scroll(
                        collection_name=alt_collection,
                        limit=5,
                        with_payload=True,
                        with_vectors=False
                    )
                    
                    points = scroll_result[0]
                    for i, point in enumerate(points):
                        print(f"\nPoint {i+1}:")
                        print(f"  ID: {point.id}")
                        print(f"  Payload: {point.payload}")
            else:
                print("\nAucune collection de roadmap trouvée")
    
    except Exception as e:
        print(f"Erreur: {str(e)}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
