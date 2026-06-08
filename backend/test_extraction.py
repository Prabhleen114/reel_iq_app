import re
import requests

from instagram_service import InstagramService
s = InstagramService()
session = s.L.context._session
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
}
html = session.get('https://www.instagram.com/nasa/', headers=headers).text

# 1. user_id
id_match = re.search(r'"profile_id":"(\d+)"', html)
if not id_match:
    id_match = re.search(r'"profilePage_uid":"(\d+)"', html)
print("user_id:", id_match.group(1) if id_match else "None")

# 2. followers from meta
meta_match = re.search(r'<meta\s+property="og:description"\s+content="(.*?)"', html)
print("meta_desc:", meta_match.group(1) if meta_match else "None")

# 3. title
title_match = re.search(r'<title>(.*?)\s*[\(\|@]', html)
print("title:", title_match.group(1).strip() if title_match else "None")
