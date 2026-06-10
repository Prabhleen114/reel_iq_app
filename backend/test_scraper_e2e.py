"""End-to-end test: Run the scraper on _.aastha._here and print results."""
from instagram_service import InstagramService

ig = InstagramService()
result = ig.scrape_public_profile("_.aastha._here")

pd = result["profile_data"]
md = result["media_data"]

print()
print("=" * 50)
print("  FINAL SCRAPER OUTPUT")
print("=" * 50)
print(f"  username:            {pd['username']}")
print(f"  display_name:        {pd['display_name']}")
print(f"  followers_count:     {pd['followers_count']}")
print(f"  follows_count:       {pd['follows_count']}")
print(f"  media_count:         {pd['media_count']}")
print(f"  biography:           {pd['biography'][:100] if pd['biography'] else '(empty)'}")
print(f"  category:            {pd['category']}")
print(f"  profile_picture_url: {pd['profile_picture_url'][:80] if pd['profile_picture_url'] else '(empty)'}...")
print(f"  posts collected:     {len(md)}")
print("=" * 50)

# Validate
errors = []
if pd["followers_count"] == 0:
    errors.append("followers_count is STILL 0!")
if pd["follows_count"] == 0:
    errors.append("follows_count is STILL 0!")
if pd["media_count"] == 0:
    errors.append("media_count is STILL 0!")
if not pd["profile_picture_url"]:
    errors.append("profile_picture_url is EMPTY!")

if errors:
    print("\n  [FAIL] Issues found:")
    for e in errors:
        print(f"    - {e}")
else:
    print("\n  [PASS] All values are non-zero! Scraper is working correctly.")
