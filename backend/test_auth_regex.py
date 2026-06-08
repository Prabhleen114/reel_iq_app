import re
import sys
from instagram_service import InstagramService

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
s = InstagramService()
session = s.L.context._session
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}
r = session.get('https://www.instagram.com/nasa/', headers=headers)
html = r.text

print("Length:", len(html))

# Try different regexes for user ID
print("profile_id:", re.findall(r'"profile_id":"(\d+)"', html)[:2])
print("profilePage_uid:", re.findall(r'"profilePage_uid":"(\d+)"', html)[:2])
print("owner_user_id:", re.findall(r'owner_user_id"\s*content="(\d+)"', html)[:2])
print("id:", set(re.findall(r'"id":"(\d+)"', html)))

# Look for follower count in meta description
meta_desc = re.findall(r'<meta\s+property="og:description"\s+content="(.*?)"', html)
print("\nog:description:", meta_desc)

meta_desc2 = re.findall(r'<meta\s+name="description"\s+content="(.*?)"', html)
print("name=description:", meta_desc2)
