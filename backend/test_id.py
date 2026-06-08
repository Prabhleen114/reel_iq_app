import requests
import re
import sys

r = requests.get('https://www.instagram.com/nasa/', headers={'User-Agent': 'Mozilla/5.0'})
print("profilePage_uid:", re.findall(r'"profilePage_uid":"(\d+)"', r.text)[:1])
print("id:", re.findall(r'"id":"(\d+)"', r.text)[:1])
print("owner_user_id:", re.findall(r'owner_user_id"\s*content="(\d+)"', r.text)[:1])
