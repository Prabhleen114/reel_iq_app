import re

html = '<meta property="og:description" content="104M Followers, 95 Following, 4,809 Posts - See Instagram photos and videos from NASA (&#064;nasa)" />'
meta_match = re.search(r'<meta\s+(?:property|name)="(?:og:)?description"\s+content="(.*?)"', html)
print(meta_match.group(1) if meta_match else "No match")
