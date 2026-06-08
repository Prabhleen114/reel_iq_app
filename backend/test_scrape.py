"""Quick end-to-end test of the production scraper."""
import sys
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

from instagram_service import InstagramService

s = InstagramService()

for uname in ['nasa', 'mrbeast', 'therock']:
    print(f"\n{'='*50}")
    print(f"  Testing: @{uname}")
    print(f"{'='*50}")
    try:
        result = s.scrape_public_profile(uname)
        pd = result['profile_data']
        md = result['media_data']
        print(f"  Name: {pd['display_name']}")
        print(f"  Bio: {pd['biography'][:80]}")
        print(f"  Followers: {pd['followers_count']:,}")
        print(f"  Following: {pd['follows_count']:,}")
        print(f"  Posts: {pd['media_count']:,}")
        print(f"  Category: {pd['category']}")
        print(f"  Media items fetched: {len(md)}")
        for m in md[:3]:
            cap = (m['caption'][:50] + '...') if m['caption'] else '(none)'
            print(f"    [{m['media_type']}] likes={m['like_count']:,} comments={m['comments_count']:,} date={m['timestamp']}")
            print(f"      {cap}")
    except Exception as e:
        print(f"  ERROR: {e}")
    
    import time
    time.sleep(5)

print("\n\nDONE - All tests complete.")
