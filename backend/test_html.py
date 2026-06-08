import re
import sys
from instagram_service import InstagramService

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
s = InstagramService()
session = s.L.context._session
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}
html = session.get('https://www.instagram.com/nasa/', headers=headers).text
print("Length:", len(html))

# Print all occurrences of '528817151' in the HTML and see what keys they are under!
matches = re.findall(r'.{0,30}528817151.{0,30}', html)
print(f"Found '528817151' {len(matches)} times:")
for m in matches[:10]:
    print("  ", m)

# Print all meta descriptions
print("\nMeta tags:")
metas = re.findall(r'<meta[^>]*>', html)
for m in metas:
    if 'description' in m or '104M' in m:
        print("  ", m)

