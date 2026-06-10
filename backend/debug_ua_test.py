"""
Test which User-Agent triggers Instagram's server-side rendering
with og:description meta tags containing follower counts.
"""
import requests
import re

USERNAME = "_.aastha._here"

user_agents = {
    "Chrome Desktop": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    "Googlebot": "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
    "Bingbot": "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
    "FacebookBot": "facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)",
    "TwitterBot": "Twitterbot/1.0",
    "curl": "curl/7.88.1",
    "Python requests": "python-requests/2.31.0",
    "WhatsApp": "WhatsApp/2.23.20.0",
    "TelegramBot": "TelegramBot (like TwitterBot)",
    "LinkedInBot": "LinkedInBot/1.0 (compatible; Mozilla/5.0; Apache-HttpClient +http://www.linkedin.com)",
    "Slackbot": "Slackbot-LinkExpanding 1.0 (+https://api.slack.com/robots)",
}

for name, ua in user_agents.items():
    try:
        headers = {
            'User-Agent': ua,
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
        }
        resp = requests.get(f'https://www.instagram.com/{USERNAME}/', headers=headers, timeout=10)
        html = resp.text
        
        has_og_desc = bool(re.search(r'og:description', html))
        has_meta_desc = bool(re.search(r'name="description"', html))
        title_match = re.search(r'<title>(.*?)</title>', html)
        title = title_match.group(1) if title_match else "N/A"
        
        followers = "N/A"
        og = re.search(r'<meta\s+(?:property="og:description"\s+content|content)="(.*?)"', html)
        if og and 'Followers' in og.group(1):
            f_m = re.search(r'([\d,.]+[KMB]?)\s+Followers', og.group(1))
            if f_m:
                followers = f_m.group(1)
        
        # Also try content-first ordering
        if followers == "N/A":
            og2 = re.search(r'<meta\s+content="(.*?)"\s+property="og:description"', html)
            if og2 and 'Followers' in og2.group(1):
                f_m = re.search(r'([\d,.]+[KMB]?)\s+Followers', og2.group(1))
                if f_m:
                    followers = f_m.group(1)
        
        print(f"{name:20s} | status={resp.status_code} | title={title[:30]:30s} | og:desc={str(has_og_desc):5s} | meta:desc={str(has_meta_desc):5s} | followers={followers}")
    except Exception as e:
        print(f"{name:20s} | ERROR: {e}")
