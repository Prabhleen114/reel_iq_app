import re
import sys
from instagram_service import InstagramService

sys.stdout.reconfigure(encoding='utf-8', errors='replace')
s = InstagramService()
session = s.L.context._session

print("--- Test 1: Full Chrome UA ---")
headers1 = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
}
r1 = session.get('https://www.instagram.com/nasa/', headers=headers1)
print("Length:", len(r1.text))
print("Meta:", re.findall(r'<meta[^>]*>', r1.text)[:2])

print("\n--- Test 2: Simple UA ---")
headers2 = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
}
r2 = session.get('https://www.instagram.com/nasa/', headers=headers2)
print("Length:", len(r2.text))
print("Meta:", re.findall(r'<meta[^>]*>', r2.text)[:2])
