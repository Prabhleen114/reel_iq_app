"""
Diagnostic script: Fetch the anonymous Instagram HTML page for a profile
and inspect every possible source of follower/following/post data.
"""
import requests
import re
import json
import sys

USERNAME = sys.argv[1] if len(sys.argv) > 1 else "_.aastha._here"

headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}

print(f"Fetching profile: {USERNAME}")
resp = requests.get(f'https://www.instagram.com/{USERNAME}/', headers=headers, timeout=15)
html = resp.text

print(f"Status: {resp.status_code}")
print(f"Final URL: {resp.url}")
print(f"HTML length: {len(html)}")
print()

# Save full HTML
with open('debug_instagram_response.html', 'w', encoding='utf-8') as f:
    f.write(html)
print(f"Saved full HTML to debug_instagram_response.html ({len(html)} bytes)")
print()

# ── Detect bad pages ──
if 'login' in resp.url.lower():
    print("[DETECT] Redirected to LOGIN page")
if '/challenge/' in resp.url.lower():
    print("[DETECT] Redirected to CHALLENGE page")
if 'please wait' in html.lower() or 'please_wait' in html.lower():
    print("[DETECT] Instagram returned PLEASE WAIT page")
if '<title>Instagram</title>' in html and 'og:description' not in html:
    print("[DETECT] Instagram returned GENERIC page with no profile data")

# ── Title ──
title_match = re.search(r'<title>(.*?)</title>', html)
print(f"TITLE: {title_match.group(1) if title_match else 'NOT FOUND'}")
print()

# ── Meta description (name=description) ──
meta_desc = re.search(r'<meta\s+name="description"\s+content="(.*?)"', html)
if not meta_desc:
    meta_desc = re.search(r'<meta\s+content="(.*?)"\s+name="description"', html)
print(f"META DESCRIPTION: {meta_desc.group(1)[:300] if meta_desc else 'NOT FOUND'}")
print()

# ── og:description ──
og_desc_v1 = re.search(r'<meta\s+property="og:description"\s+content="(.*?)"', html)
og_desc_v2 = re.search(r'<meta\s+content="(.*?)"\s+property="og:description"', html)
og_desc = og_desc_v1 or og_desc_v2
print(f"OG DESC (property first): {og_desc_v1.group(1)[:300] if og_desc_v1 else 'NOT FOUND'}")
print(f"OG DESC (content first):  {og_desc_v2.group(1)[:300] if og_desc_v2 else 'NOT FOUND'}")
print()

# ── og:title ──
og_title_v1 = re.search(r'<meta\s+property="og:title"\s+content="(.*?)"', html)
og_title_v2 = re.search(r'<meta\s+content="(.*?)"\s+property="og:title"', html)
print(f"OG TITLE (property first): {og_title_v1.group(1)[:200] if og_title_v1 else 'NOT FOUND'}")
print(f"OG TITLE (content first):  {og_title_v2.group(1)[:200] if og_title_v2 else 'NOT FOUND'}")
print()

# ── og:image ──
og_img_v1 = re.search(r'<meta\s+property="og:image"\s+content="(.*?)"', html)
og_img_v2 = re.search(r'<meta\s+content="(.*?)"\s+property="og:image"', html)
print(f"OG IMAGE (property first): {og_img_v1.group(1)[:120] if og_img_v1 else 'NOT FOUND'}")
print(f"OG IMAGE (content first):  {og_img_v2.group(1)[:120] if og_img_v2 else 'NOT FOUND'}")
print()

# ── LD+JSON ──
ldjson_matches = re.findall(r'<script\s+type="application/ld\+json">(.*?)</script>', html, re.DOTALL)
print(f"LD+JSON blocks found: {len(ldjson_matches)}")
for i, block in enumerate(ldjson_matches):
    print(f"  LD+JSON[{i}]: {block[:400]}")
print()

# ── _sharedData ──
shared_data = re.search(r'window\._sharedData\s*=\s*(\{.*?\});\s*</script>', html, re.DOTALL)
if shared_data:
    print("_sharedData: FOUND")
    try:
        sd = json.loads(shared_data.group(1))
        print(f"  Keys: {list(sd.keys())}")
    except:
        print(f"  (could not parse JSON)")
else:
    print("_sharedData: NOT FOUND")

# ── __additionalDataLoaded ──
additional_data = re.search(r'window\.__additionalDataLoaded\s*\([^,]*,\s*(\{.*?\})\s*\)', html, re.DOTALL)
print(f"__additionalDataLoaded: {'FOUND' if additional_data else 'NOT FOUND'}")
print()

# ── Try extraction with our actual regex ──
print("=== EXTRACTION ATTEMPTS ===")
if og_desc:
    desc = og_desc.group(1)
    f_m = re.search(r'([\d,.]+[KMB]?)\s+Followers', desc, re.IGNORECASE)
    fo_m = re.search(r'([\d,.]+[KMB]?)\s+Following', desc, re.IGNORECASE)
    p_m = re.search(r'([\d,.]+[KMB]?)\s+Posts', desc, re.IGNORECASE)
    print(f"  Followers extracted: {f_m.group(1) if f_m else 'FAILED'}")
    print(f"  Following extracted: {fo_m.group(1) if fo_m else 'FAILED'}")
    print(f"  Posts extracted:     {p_m.group(1) if p_m else 'FAILED'}")
elif meta_desc:
    desc = meta_desc.group(1)
    f_m = re.search(r'([\d,.]+[KMB]?)\s+Followers', desc, re.IGNORECASE)
    fo_m = re.search(r'([\d,.]+[KMB]?)\s+Following', desc, re.IGNORECASE)
    p_m = re.search(r'([\d,.]+[KMB]?)\s+Posts', desc, re.IGNORECASE)
    print(f"  Followers extracted (from meta desc): {f_m.group(1) if f_m else 'FAILED'}")
    print(f"  Following extracted (from meta desc): {fo_m.group(1) if fo_m else 'FAILED'}")
    print(f"  Posts extracted (from meta desc):     {p_m.group(1) if p_m else 'FAILED'}")
else:
    print("  No og:description or meta description found! Checking raw HTML for count patterns...")
    # Brute force search for follower patterns anywhere in HTML
    all_follower_matches = re.findall(r'([\d,.]+[KMB]?)\s+[Ff]ollower', html)
    print(f"  Raw 'Follower' matches in HTML: {all_follower_matches}")
    all_following_matches = re.findall(r'([\d,.]+[KMB]?)\s+[Ff]ollowing', html)
    print(f"  Raw 'Following' matches in HTML: {all_following_matches}")
    all_post_matches = re.findall(r'([\d,.]+[KMB]?)\s+[Pp]osts?', html)
    print(f"  Raw 'Post' matches in HTML: {all_post_matches}")

print()
print("=== HTML FIRST 5000 CHARS ===")
print(html[:5000])
print("=== HTML END ===")
