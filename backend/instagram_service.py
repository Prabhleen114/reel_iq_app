import os
import json
import re
import time
import glob
from typing import Dict, Any, List
import instaloader
import requests
from itertools import islice

try:
    from groq import Groq
    HAS_GROQ = True
except ImportError:
    HAS_GROQ = False

class InstagramService:
    def __init__(self):
        self.api_key = os.environ.get("GROQ_API_KEY", "").strip()
        self.client = None
        if HAS_GROQ and self.api_key:
            try:
                self.client = Groq(api_key=self.api_key)
            except Exception as e:
                print(f"InstagramService Warning: Failed to initialize Groq client: {e}")
                
        self.L = instaloader.Instaloader(
            download_pictures=False,
            download_video_thumbnails=False,
            download_videos=False,
            download_geotags=False,
            download_comments=False,
            save_metadata=False,
            compress_json=False
        )
        
        # Load authenticated session
        self._session_loaded = False
        self._load_session()

    def _load_session(self):
        """Search for and load an authenticated Instaloader session file."""
        # Session files are stored at: C:\Users\<user>\AppData\Local\Instaloader\session-<username>
        session_dir = os.path.join(os.path.expanduser("~"), "AppData", "Local", "Instaloader")
        
        # Also check the backend directory for a manually placed session file
        backend_dir = os.path.dirname(os.path.abspath(__file__))
        
        session_file = None
        session_username = None
        
        # 1. Check env var for explicit session config
        env_ig_user = os.environ.get("INSTAGRAM_SESSION_USER", "").strip()
        if env_ig_user:
            candidate = os.path.join(session_dir, f"session-{env_ig_user}")
            if os.path.exists(candidate):
                session_file = candidate
                session_username = env_ig_user
                print(f"[INSTALOADER] Found session via INSTAGRAM_SESSION_USER env var: {session_file}")
        
        # 2. Auto-detect any session file in the default directory
        if not session_file and os.path.isdir(session_dir):
            pattern = os.path.join(session_dir, "session-*")
            matches = glob.glob(pattern)
            if matches:
                session_file = matches[0]
                session_username = os.path.basename(session_file).replace("session-", "")
                print(f"[INSTALOADER] Auto-detected session file: {session_file}")
        
        # 3. Check backend directory for a session file
        if not session_file:
            pattern = os.path.join(backend_dir, "session-*")
            matches = glob.glob(pattern)
            if matches:
                session_file = matches[0]
                session_username = os.path.basename(session_file).replace("session-", "")
                print(f"[INSTALOADER] Found session file in backend dir: {session_file}")
        
        if not session_file:
            print(f"[INSTALOADER WARNING] No session file found.")
            print(f"[INSTALOADER WARNING] Searched: {session_dir}")
            print(f"[INSTALOADER WARNING] Searched: {backend_dir}")
            print(f"[INSTALOADER WARNING] Run 'python create_session.py <username>' to create one.")
            return
        
        try:
            self.L.load_session_from_file(session_username, session_file)
            self._session_loaded = True
            print(f"[INSTALOADER] Instagram session loaded successfully for @{session_username}")
            print(f"[INSTALOADER] Session file path: {session_file}")
        except Exception as e:
            print(f"[INSTALOADER ERROR] Failed to load session from {session_file}: {e}")
            print(f"[INSTALOADER ERROR] Session may be expired. Re-run 'python create_session.py {session_username}'")

    def calculate_statistics(self, profile_data: Dict[str, Any], media_data: List[Dict[str, Any]]) -> Dict[str, Any]:
        followers = profile_data.get('followers_count', 0)
        total_likes = 0
        total_comments = 0
        valid_media_count = len(media_data)

        if valid_media_count == 0:
            return {
                "average_likes": 0,
                "average_comments": 0,
                "engagement_rate": 0,
                "posting_frequency": "Unknown",
                "most_used_hashtags": [],
                "top_performing_content": None,
                "lowest_performing_content": None
            }

        hashtags_freq = {}
        sorted_media = []

        for item in media_data:
            likes = item.get('like_count', 0)
            comments = item.get('comments_count', 0)
            caption = item.get('caption', '')
            
            total_likes += likes
            total_comments += comments
            
            # Extract hashtags
            words = caption.split()
            for w in words:
                if w.startswith('#') and len(w) > 1:
                    tag = w.lower()
                    hashtags_freq[tag] = hashtags_freq.get(tag, 0) + 1
            
            # For sorting
            engagement = likes + comments
            sorted_media.append({
                "id": item.get("id"),
                "engagement": engagement,
                "permalink": item.get("permalink", ""),
                "thumbnail_url": item.get("thumbnail_url") or item.get("media_url", "")
            })

        avg_likes = total_likes / valid_media_count
        avg_comments = total_comments / valid_media_count
        
        engagement_rate = 0
        if followers > 0:
            engagement_rate = ((total_likes + total_comments) / followers) * 100

        # Sort hashtags by frequency
        sorted_hashtags = sorted(hashtags_freq.items(), key=lambda x: x[1], reverse=True)
        top_hashtags = [k for k, v in sorted_hashtags[:10]]

        # Top and lowest performing
        sorted_media.sort(key=lambda x: x["engagement"], reverse=True)
        top_content = sorted_media[0] if sorted_media else None
        lowest_content = sorted_media[-1] if sorted_media else None

        # Determine frequency (very basic heuristic)
        posting_frequency = f"{valid_media_count} recent posts analyzed"

        return {
            "average_likes": round(avg_likes, 1),
            "average_comments": round(avg_comments, 1),
            "engagement_rate": round(engagement_rate, 2),
            "posting_frequency": posting_frequency,
            "most_used_hashtags": top_hashtags,
            "top_performing_content": top_content,
            "lowest_performing_content": lowest_content
        }

    def analyze_profile(self, profile_data: Dict[str, Any], stats: Dict[str, Any]) -> Dict[str, Any]:
        """
        Uses Groq AI to generate a comprehensive profile analysis.
        """
        if not self.client:
            # Fallback to local heuristics
            return self._analyze_locally(profile_data, stats)

        system_prompt = (
            "You are ReelIQ, an elite Instagram Growth Strategist. Analyze the given Instagram profile statistics.\n"
            "You must return a raw JSON object and nothing else. The JSON object must match this schema:\n"
            "{\n"
            '  "overall_score": int (0-100),\n'
            '  "strengths": [string],\n'
            '  "weaknesses": [string],\n'
            '  "growth_recommendations": [string],\n'
            '  "suggested_content_pillars": [string],\n'
            '  "suggested_hashtag_groups": [string],\n'
            '  "suggested_posting_schedule": "string",\n'
            '  "suggested_reel_ideas": [string]\n'
            "}"
        )

        user_prompt = (
            f"Profile:\n"
            f"- Username: {profile_data.get('username')}\n"
            f"- Bio: {profile_data.get('biography')}\n"
            f"- Followers: {profile_data.get('followers_count')}\n"
            f"- Posts: {profile_data.get('media_count')}\n\n"
            f"Recent Performance Stats:\n"
            f"- Engagement Rate: {stats.get('engagement_rate')}%\n"
            f"- Average Likes: {stats.get('average_likes')}\n"
            f"- Average Comments: {stats.get('average_comments')}\n"
            f"- Most Used Hashtags: {', '.join(stats.get('most_used_hashtags', []))}\n\n"
            f"Provide a harsh but constructive audit. If engagement rate is < 2%, note it as a weakness."
        )

        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                model="llama-3.1-8b-instant",
                temperature=0.4,
                response_format={"type": "json_object"}
            )
            result_text = chat_completion.choices[0].message.content
            return json.loads(result_text)
        except Exception as e:
            print(f"InstagramService Warning: Groq call failed: {e}")
            return self._analyze_locally(profile_data, stats)

    def _analyze_locally(self, profile_data: Dict[str, Any], stats: Dict[str, Any]) -> Dict[str, Any]:
        eng_rate = stats.get('engagement_rate', 0)
        score = 60
        strengths = []
        weaknesses = []

        if eng_rate > 5:
            score += 20
            strengths.append("Exceptional engagement rate, highly loyal audience.")
        elif eng_rate > 2:
            score += 10
            strengths.append("Healthy engagement rate above industry average.")
        else:
            score -= 10
            weaknesses.append("Low engagement rate relative to follower count.")

        if not stats.get('most_used_hashtags'):
            weaknesses.append("Missing hashtag strategy on recent posts.")
        else:
            strengths.append("Consistent use of hashtags for reach.")

        return {
            "overall_score": max(min(score, 100), 0),
            "strengths": strengths if strengths else ["Consistent posting history"],
            "weaknesses": weaknesses if weaknesses else ["Lack of clear CTA in recent reels"],
            "growth_recommendations": [
                "Focus on hook-first 3-second intros",
                "Experiment with trending audio to boost algorithmic reach",
                "Add direct CTA in the first line of captions"
            ],
            "suggested_content_pillars": [
                "Educational / How-to",
                "Behind the Scenes",
                "Personal Story / Connection"
            ],
            "suggested_hashtag_groups": [
                f"Niche tags: {', '.join(stats.get('most_used_hashtags', [])[:3])}" if stats.get('most_used_hashtags') else "Niche specific tags",
                "Broad audience tags"
            ],
            "suggested_posting_schedule": "Post 4 times a week, ideally between 6 PM - 8 PM.",
            "suggested_reel_ideas": [
                "A 'Mistakes I made so you do not have to' reel",
                "A day in the life vlog snippet",
                "A controversial but educational opinion piece"
            ]
        }

    @staticmethod
    def _parse_count(text: str) -> int:
        """Parse abbreviated counts like '104M', '1.2K', '4,437'."""
        text = text.strip().replace(',', '')
        multiplier = 1
        if text.upper().endswith('K'):
            multiplier = 1000
            text = text[:-1]
        elif text.upper().endswith('M'):
            multiplier = 1000000
            text = text[:-1]
        elif text.upper().endswith('B'):
            multiplier = 1000000000
            text = text[:-1]
        try:
            return int(float(text) * multiplier)
        except ValueError:
            return 0

    def scrape_public_profile(self, username: str) -> Dict[str, Any]:
        """
        Scrapes public Instagram profile data using a hybrid approach:
        1. HTML meta tags for follower/following/post counts and user ID
        2. web_profile_info API for bio/category (when not rate-limited)
        3. Feed API for post data (most reliable)
        """
        print("\n[STEP 1] Using Hybrid Scraper - Initializing session")
        print(f"[DEBUG] scrape_public_profile called with username: {repr(username)}")
        print(f"[DEBUG] Authenticated session: {self._session_loaded}")
        normalized_username = username.strip().lstrip('@').lower()
        print(f"[DEBUG] Normalized username: {repr(normalized_username)}")

        if not self._session_loaded:
            raise ValueError("No authenticated Instagram session. Run 'python create_session.py <username>' first.")

        session = self.L.context._session
        cookies = {c.name: c.value for c in session.cookies}
        print(f"[DEBUG] Session cookies attached to requests.Session: {cookies}")
        
        api_headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
            'X-IG-App-ID': '936619743392459',
            'X-CSRFToken': cookies.get('csrftoken', ''),
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': '*/*',
        }

        user_id = None
        display_name = normalized_username
        followers_count = 0
        following_count = 0
        media_count = 0
        biography = ''
        category = 'Creator'
        is_private = False
        profile_pic = ''
        
        html_scrape_success = False
        web_profile_status = None

        # ── Step 2: Get follower/following/post counts and user_id from HTML ──
        print("[STEP 2] Fetching HTML profile page for meta tags and user ID...")
        html = None
        html_scrape_success = False
        
        # Chrome UA for authenticated session
        chrome_headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
        }
        
        # Non-Chrome UA for anonymous fallback (Instagram serves SSR HTML with
        # og:description meta tags to non-browser User-Agents like curl/bots,
        # but returns an empty JS SPA shell to Chrome/Firefox/Safari UAs)
        anon_headers = {
            'User-Agent': 'curl/7.88.1',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
        }
        
        try:
            print(f"[DEBUG] Fetching authenticated HTML for {repr(normalized_username)}")
            page_resp = session.get(f'https://www.instagram.com/{normalized_username}/', headers=chrome_headers, timeout=10)
            print(f"[DEBUG] HTML page request URL: https://www.instagram.com/{normalized_username}/")
            print(f"[DEBUG] HTML page final URL: {page_resp.url}")
            if page_resp.history:
                print(f"[DEBUG] HTML page redirect chain: {[r.url for r in page_resp.history]}")
            print(f"[DEBUG] HTML page status: {page_resp.status_code}, length: {len(page_resp.text)}")

            if page_resp.status_code == 200 and "login" not in page_resp.url.lower():
                # Check if the page is a generic SPA shell (no meta tags)
                if 'og:description' in page_resp.text:
                    html = page_resp.text
                    print("[DEBUG] Authenticated HTML contains og:description - using it")
                else:
                    print("[DEBUG] Authenticated HTML is SPA shell (no og:description) - falling through to anonymous")
                    raise ValueError("Authenticated page is an empty SPA shell")
            else:
                raise ValueError(f"Bad status or redirected to {page_resp.url}")
        except Exception as e:
            print(f"[DEBUG] Authenticated HTML page fetch failed: {e}")
            print(f"[DEBUG] Attempting anonymous HTML fallback for {repr(normalized_username)} (curl UA)...")
            try:
                anon_resp = requests.get(f'https://www.instagram.com/{normalized_username}/', headers=anon_headers, timeout=15)
                print(f"[DEBUG] Anonymous HTML fallback status: {anon_resp.status_code}")
                print(f"[DEBUG] Anonymous HTML fallback final URL: {anon_resp.url}")
                
                # Detect bad page types
                anon_html = anon_resp.text
                if 'login' in anon_resp.url.lower():
                    print("[DEBUG] Instagram returned LOGIN page")
                elif '/challenge/' in anon_resp.url.lower():
                    print("[DEBUG] Instagram returned CHALLENGE page")
                elif 'please wait' in anon_html.lower() or 'please_wait' in anon_html.lower():
                    print("[DEBUG] Instagram returned PLEASE WAIT page")
                elif '<title>Instagram</title>' in anon_html and 'og:description' not in anon_html:
                    print("[DEBUG] Instagram returned GENERIC SPA shell (no profile data)")
                
                if anon_resp.status_code == 200 and 'og:description' in anon_html:
                    html = anon_html
                    print("[DEBUG] Anonymous fallback HTML contains og:description - using it")
                elif anon_resp.status_code == 200:
                    print("[DEBUG] Anonymous fallback returned 200 but no og:description found")
                    # Save for debugging
                    try:
                        debug_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'debug_instagram_response.html')
                        with open(debug_path, 'w', encoding='utf-8') as f:
                            f.write(anon_html[:5000])
                        print(f"[DEBUG] Saved first 5000 chars to {debug_path}")
                    except Exception:
                        pass
            except Exception as anon_e:
                print(f"[DEBUG] Anonymous HTML fallback failed: {anon_e}")

        # ── Parse HTML if we got a good page ──
        if html:
            try:
                # Save debug HTML
                try:
                    debug_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'debug_instagram_response.html')
                    with open(debug_path, 'w', encoding='utf-8') as f:
                        f.write(html[:5000])
                    print(f"[DEBUG] Saved first 5000 chars of HTML to {debug_path}")
                except Exception:
                    pass
                
                html_scrape_success = True
                
                # Extract user_id
                id_match = re.search(r'"profile_id":"(\d+)"', html)
                if not id_match:
                    id_match = re.search(r'"profilePage_uid":"(\d+)"', html)
                
                if id_match:
                    user_id = id_match.group(1)
                    print(f"[DEBUG] Found user_id from HTML: {user_id}")
                else:
                    print("[DEBUG] user_id NOT FOUND in HTML")

                # Extract title for display name
                title_match = re.search(r'<title>(.*?)\s*[\(\|@]', html)
                if title_match:
                    display_name = title_match.group(1).strip()
                    print(f"[DEBUG] Found display_name from title: {repr(display_name)}")
                else:
                    print("[DEBUG] display_name NOT FOUND in title")

                # Extract profile picture URL from og:image (try both attribute orderings)
                pic_match = re.search(r'<meta\s+property="og:image"\s+content="(.*?)"', html)
                if not pic_match:
                    pic_match = re.search(r'<meta\s+content="(.*?)"\s+property="og:image"', html)
                if pic_match:
                    profile_pic = pic_match.group(1).replace('&amp;', '&')
                    print(f"[DEBUG] Found profile_pic from HTML: {profile_pic[:80]}...")
                else:
                    print("[DEBUG] profile_pic NOT FOUND in HTML")

                # Extract counts from og:description (try both attribute orderings)
                meta_match = re.search(r'<meta\s+property="og:description"\s+content="(.*?)"', html)
                if not meta_match:
                    meta_match = re.search(r'<meta\s+content="(.*?)"\s+property="og:description"', html)
                
                # Also try name="description" as a secondary source
                if not meta_match:
                    meta_match = re.search(r'<meta\s+name="description"\s+content="(.*?)"', html)
                if not meta_match:
                    meta_match = re.search(r'<meta\s+content="(.*?)"\s+name="description"', html)
                    
                if meta_match:
                    desc = meta_match.group(1)
                    print(f"[DEBUG] Meta description found: {desc[:200]}")
                    
                    f_m = re.search(r'([\d,.]+[KMB]?)\s+Followers', desc, re.IGNORECASE)
                    if f_m:
                        followers_count = self._parse_count(f_m.group(1))
                        print(f"[DEBUG] Followers extracted: {followers_count} (raw: {f_m.group(1)})")
                    else:
                        print("[DEBUG] Followers extraction FAILED from meta description")
                        
                    fo_m = re.search(r'([\d,.]+[KMB]?)\s+Following', desc, re.IGNORECASE)
                    if fo_m:
                        following_count = self._parse_count(fo_m.group(1))
                        print(f"[DEBUG] Following extracted: {following_count} (raw: {fo_m.group(1)})")
                    else:
                        print("[DEBUG] Following extraction FAILED from meta description")
                        
                    p_m = re.search(r'([\d,.]+[KMB]?)\s+Posts', desc, re.IGNORECASE)
                    if p_m:
                        media_count = self._parse_count(p_m.group(1))
                        print(f"[DEBUG] Posts extracted: {media_count} (raw: {p_m.group(1)})")
                    else:
                        print("[DEBUG] Posts extraction FAILED from meta description")
                    
                    # Extract bio from description (format: "NNN Followers, NNN Following, NNN Posts - See Instagram photos and videos from DisplayName (@username)")
                    # Sometimes there's a bio snippet after the counts
                    bio_match = re.search(r'Posts\s*[-\u2013]\s*(?:See Instagram photos and videos from\s+)?(?:.*?(?:\(@[^)]+\))?\s*)?[:\-\u2013]?\s*["\u201c]?(.*?)(?:["\u201d]?\s*$)', desc)
                    if not bio_match:
                        # Try to extract bio from separate meta tag
                        bio_meta = re.search(r'"biography":"(.*?)"', html)
                        if bio_meta:
                            biography = bio_meta.group(1).encode().decode('unicode_escape', errors='ignore')
                            print(f"[DEBUG] Biography from embedded JSON: {biography[:100]}")
                else:
                    print("[DEBUG] No meta description or og:description found in HTML")
                    print("[DEBUG] HTML title tag content:", re.search(r'<title>(.*?)</title>', html).group(1) if re.search(r'<title>(.*?)</title>', html) else "N/A")
            except Exception as parse_e:
                print(f"[DEBUG] HTML parsing failed: {parse_e}")
                import traceback
                traceback.print_exc()
        else:
            print("[DEBUG] No usable HTML obtained from either authenticated or anonymous request")

        # ── Step 3: Try web_profile_info API for bio/category ──
        print("[STEP 3] Attempting to fetch rich profile metadata (web_profile_info API)...")
        try:
            time.sleep(1)
            print(f"[DEBUG] Fetching web_profile_info for {repr(normalized_username)}")
            api_headers['Referer'] = f'https://www.instagram.com/{normalized_username}/'
            req_url = f'https://www.instagram.com/api/v1/users/web_profile_info/?username={normalized_username}'
            api_resp = session.get(req_url, headers=api_headers)
            print(f"[DEBUG] web_profile_info request URL: {req_url}")
            print(f"[DEBUG] web_profile_info final URL: {api_resp.url}")
            if api_resp.history:
                print(f"[DEBUG] web_profile_info redirect chain: {[r.url for r in api_resp.history]}")
            print(f"[DEBUG] web_profile_info status: {api_resp.status_code}")
            web_profile_status = api_resp.status_code

            if api_resp.status_code == 200:
                api_data = api_resp.json()
                user = api_data.get('data', {}).get('user', {})
                biography = user.get('biography', '') or ''
                category = user.get('category_name', '') or 'Creator'
                is_private = user.get('is_private', False)
                if user.get('profile_pic_url_hd'):
                    profile_pic = user['profile_pic_url_hd']
                if user.get('id') and not user_id:
                    user_id = user['id']
                if user.get('edge_followed_by', {}).get('count'):
                    followers_count = user['edge_followed_by']['count']
                if user.get('edge_follow', {}).get('count'):
                    following_count = user['edge_follow']['count']
                if user.get('edge_owner_to_timeline_media', {}).get('count'):
                    media_count = user['edge_owner_to_timeline_media']['count']
                if user.get('full_name'):
                    display_name = user['full_name']
                print(f"[DEBUG] web_profile_info API loaded successfully")
            else:
                print(f"[DEBUG] web_profile_info unavailable ({api_resp.status_code}), using meta tag data")
        except Exception as e:
            print(f"[DEBUG] web_profile_info API error: {e}")

        # ── Step 3.5: Instaloader Fallback ──
        if not html_scrape_success or web_profile_status == 429:
            print("[STEP 3.5] Using Instaloader fallback due to HTML failure or 429 status...")
            try:
                print(f"[DEBUG] Instaloader Profile.from_username() called with exact string: {repr(normalized_username)}")
                profile = instaloader.Profile.from_username(self.L.context, normalized_username)
                
                if profile.userid and not user_id:
                    user_id = str(profile.userid)
                if profile.followers > 0:
                    followers_count = profile.followers
                if profile.followees > 0:
                    following_count = profile.followees
                if profile.mediacount > 0:
                    media_count = profile.mediacount
                if profile.biography:
                    biography = profile.biography
                if profile.profile_pic_url:
                    profile_pic = profile.profile_pic_url
                if profile.full_name:
                    display_name = profile.full_name
                is_private = profile.is_private
                
                print(f"[DEBUG] Instaloader fallback successful. Followers: {followers_count}, Posts: {media_count}")
            except Exception as e:
                print(f"[DEBUG] Instaloader fallback failed: {e}")

        if is_private:
            raise ValueError("This account is private. Cannot analyze private profiles.")

        profile_data = {
            "username": normalized_username,
            "display_name": display_name,
            "biography": biography,
            "category": category,
            "followers_count": followers_count,
            "follows_count": following_count,
            "media_count": media_count,
            "profile_picture_url": profile_pic,
        }
        print(f"[DEBUG] Profile data: followers={followers_count}, following={following_count}, posts={media_count}")

        # ── Step 4: Get posts via Feed API (most reliable) ──
        print("[STEP 4] Fetching latest posts via Feed API...")
        media_data = []
        if user_id:
            try:
                print(f"[DEBUG] Fetching posts via feed API for user_id={user_id}...")
                time.sleep(1)
                api_headers['Referer'] = f'https://www.instagram.com/{normalized_username}/'

                all_items = []
                max_id = None
                # Paginate to get up to 25 posts (Instagram returns ~12 per page)
                for page in range(3):
                    url = f'https://www.instagram.com/api/v1/feed/user/{user_id}/?count=25'
                    if max_id:
                        url += f'&max_id={max_id}'
                    feed_resp = session.get(url, headers=api_headers)
                    print(f"[DEBUG] Feed API request URL: {url}")
                    print(f"[DEBUG] Feed API final URL: {feed_resp.url}")
                    if feed_resp.history:
                        print(f"[DEBUG] Feed API redirect chain: {[r.url for r in feed_resp.history]}")
                    print(f"[DEBUG] Feed API page {page+1} status: {feed_resp.status_code}")

                    if feed_resp.status_code != 200:
                        print(f"[DEBUG] Feed API error: {feed_resp.text[:200]}")
                        break

                    feed_data = feed_resp.json()
                    items = feed_data.get('items', [])
                    all_items.extend(items)
                    print(f"[DEBUG] Got {len(items)} posts (total: {len(all_items)})")

                    if len(all_items) >= 25 or not feed_data.get('more_available', False):
                        break
                    max_id = feed_data.get('next_max_id')
                    if not max_id:
                        break
                    time.sleep(1)

                # Also extract bio from first post's user object if we still don't have it
                if not biography and all_items:
                    first_user = all_items[0].get('user', {})
                    biography = first_user.get('biography', '') or ''
                    if first_user.get('category'):
                        category = first_user['category']
                    if first_user.get('follower_count') and not followers_count:
                        followers_count = first_user['follower_count']
                    if first_user.get('following_count') and not following_count:
                        following_count = first_user['following_count']
                    if first_user.get('media_count') and not media_count:
                        media_count = first_user['media_count']
                    # Update profile_data with any newly discovered data
                    profile_data['biography'] = biography
                    profile_data['category'] = category
                    profile_data['followers_count'] = followers_count or profile_data['followers_count']
                    profile_data['follows_count'] = following_count or profile_data['follows_count']
                    profile_data['media_count'] = media_count or profile_data['media_count']

                for item in all_items[:25]:
                    caption_text = ''
                    if item.get('caption'):
                        caption_text = item['caption'].get('text', '')
                    media_data.append({
                        "id": item.get('code', ''),
                        "caption": caption_text,
                        "media_type": "VIDEO" if item.get('media_type') == 2 else "IMAGE",
                        "media_url": "",
                        "thumbnail_url": "",
                        "permalink": f"https://www.instagram.com/p/{item.get('code', '')}/",
                        "timestamp": time.strftime('%Y-%m-%dT%H:%M:%S', time.gmtime(item.get('taken_at', 0))) if item.get('taken_at') else None,
                        "like_count": item.get('like_count', 0),
                        "comments_count": item.get('comment_count', 0),
                    })
                print(f"[DEBUG] Extracted {len(media_data)} posts for '{normalized_username}'")
            except Exception as e:
                print(f"[ERROR] Feed API error: {type(e).__name__} - {str(e)}")

        # --- DIAGNOSTICS FOR USER ---
        print("\n=== SCRAPER RAW VALUES ===")
        print(f"  Username: {profile_data['username']}")
        print(f"  Followers: {profile_data['followers_count']}")
        print(f"  Following: {profile_data['follows_count']}")
        print(f"  Media Count: {profile_data['media_count']}")
        print(f"  Posts collected: {len(media_data)}")
        if len(media_data) > 0:
            print("\n  Top 3 posts:")
            # sort by likes to show top 3
            sorted_media = sorted(media_data, key=lambda x: x['like_count'], reverse=True)
            for i, p in enumerate(sorted_media[:3]):
                cap = p['caption'][:40].replace('\n', ' ').encode('ascii', errors='replace').decode('ascii') if p['caption'] else '(no caption)'
                print(f"    {i+1}. Likes: {p['like_count']} | Comments: {p['comments_count']} | Cap: {cap}...")
        print("==========================\n")

        return {
            "profile_data": profile_data,
            "media_data": media_data
        }

    def analyze_public_profile(self, profile_data: Dict[str, Any], stats: Dict[str, Any], username: str) -> Dict[str, Any]:
        """
        Uses Groq AI to generate an 18-point audit based on scraped profile data and calculated stats.
        """
        
        print("\n=== GROQ INPUT PAYLOAD ===")
        print(f"profile_data: {json.dumps(profile_data, indent=2)[:500]}...")
        print(f"statistics: {json.dumps(stats, indent=2)[:500]}...")
        print(f"number of media items: {stats.get('total_posts_analyzed', 0)}")
        print("==========================\n")

        if not HAS_GROQ or not self.client:
            print("[WARNING] Groq API client not initialized. Returning dummy data.")

        system_prompt = (
            "You are ReelIQ, an elite Instagram Growth Strategist. Analyze the given public Instagram profile statistics and content.\n"
            "You must return a raw JSON object and nothing else. The JSON object must contain exactly these 18 fields:\n"
            "{\n"
            '  "profile_score": int (0-100),\n'
            '  "bio_score": int (0-100),\n'
            '  "content_quality_score": int (0-100),\n'
            '  "consistency_score": int (0-100),\n'
            '  "growth_potential_score": int (0-100),\n'
            '  "niche_detection": "string",\n'
            '  "audience_persona_detection": "string",\n'
            '  "top_content_pillars": [string],\n'
            '  "top_hook_patterns": [string],\n'
            '  "weak_hook_patterns": [string],\n'
            '  "posting_frequency_analysis": "string",\n'
            '  "hashtag_strategy_analysis": "string",\n'
            '  "competitor_positioning": "string (e.g. Beginner, Growing, Established, Authority)",\n'
            '  "brand_strength_analysis": "string",\n'
            '  "10_reel_ideas": [string],\n'
            '  "10_hook_ideas": [string],\n'
            '  "10_caption_ideas": [string],\n'
            '  "30_day_growth_plan": [string]\n'
            "}"
        )

        user_prompt = (
            f"Profile: @{username}\n"
            f"- Display Name: {profile_data.get('display_name')}\n"
            f"- Bio: {profile_data.get('biography')}\n"
            f"- Category: {profile_data.get('category')}\n"
            f"- Followers: {profile_data.get('followers_count')}\n"
            f"- Following: {profile_data.get('follows_count')}\n"
            f"- Posts: {profile_data.get('media_count')}\n\n"
            f"Recent Performance Stats (Last 25 Posts):\n"
            f"- Engagement Rate: {stats.get('engagement_rate')}%\n"
            f"- Average Likes: {stats.get('average_likes')}\n"
            f"- Average Comments: {stats.get('average_comments')}\n"
            f"- Most Used Hashtags: {', '.join(stats.get('most_used_hashtags', []))}\n"
            f"- Posting Frequency Overview: {stats.get('posting_frequency')}\n\n"
            f"Provide a highly detailed, 18-point constructive audit."
        )

        try:
            chat_completion = self.client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                model="llama-3.1-8b-instant",
                temperature=0.4,
                response_format={"type": "json_object"}
            )
            result_text = chat_completion.choices[0].message.content
            return json.loads(result_text)
        except Exception as e:
            raise ValueError(f"Groq Analysis Failed: {str(e)}")
