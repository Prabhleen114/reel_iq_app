import requests
import json
import sys

sys.stdout.reconfigure(encoding='utf-8', errors='replace')

url = "http://127.0.0.1:8000/instagram/public-profile-analysis"
payload = {"username": "nasa"}
headers = {"Content-Type": "application/json"}

try:
    print(f"Testing {url} with {payload}")
    r = requests.post(url, json=payload)
    print(f"Status Code: {r.status_code}")
    data = r.json()
    
    if "profileSnapshot" in data:
        print("\n--- profileSnapshot ---")
        ps = data["profileSnapshot"]
        for k in ["followers_count", "follows_count", "media_count", "biography"]:
            print(f"  {k}: {ps.get(k)}")
            
    if "statistics" in data:
        print("\n--- statistics ---")
        st = data["statistics"]
        for k in ["total_posts_analyzed", "average_likes", "average_comments", "total_likes", "total_comments"]:
            print(f"  {k}: {st.get(k)}")
            
        print("\n  Top 3 Posts (from stats):")
        for i, m in enumerate(st.get("top_posts", [])[:3]):
            print(f"    {i+1}. Likes: {m.get('like_count')} | Comments: {m.get('comments_count')}")
            cap = m.get('caption', '')
            print(f"       Caption: {cap[:60]}...")
            
    if "aiAnalysis" in data:
        print("\n--- aiAnalysis ---")
        ai = data["aiAnalysis"]
        print(f"  profile_score: {ai.get('profile_score')}")
        print(f"  niche_detection: {ai.get('niche_detection')}")
        
except Exception as e:
    print(f"Error calling endpoint: {e}")
