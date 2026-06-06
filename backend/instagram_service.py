import os
import json
from typing import Dict, Any, List
import instaloader
from itertools import islice

import glob

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

    def scrape_public_profile(self, username: str) -> Dict[str, Any]:
        """
        Scrapes public Instagram profile data using Instaloader.
        Collects profile info and latest 25 posts.
        """
        print(f"[DEBUG] scrape_public_profile called with username: '{username}'")
        print(f"[DEBUG] Authenticated session: {self._session_loaded}")
        # Ensure normalization
        normalized_username = username.strip().lstrip('@').lower()
        print(f"[DEBUG] Normalized username: '{normalized_username}'")
        
        try:
            print(f"[DEBUG] Calling instaloader.Profile.from_username for '{normalized_username}'...")
            profile = instaloader.Profile.from_username(self.L.context, normalized_username)
            print(f"[DEBUG] Successfully retrieved profile: {profile.username}")
            
            if profile.is_private:
                print(f"[DEBUG] Profile '{normalized_username}' is private.")
                raise ValueError("This account is private. Cannot analyze private profiles.")
            
            profile_data = {
                "username": profile.username,
                "display_name": profile.full_name,
                "biography": profile.biography,
                "category": getattr(profile, 'business_category_name', None) or 'Creator',
                "followers_count": profile.followers,
                "follows_count": profile.followees,
                "media_count": profile.mediacount,
                "profile_picture_url": profile.profile_pic_url
            }
            print(f"[DEBUG] Profile data extracted for '{normalized_username}'. Extracting media...")
            
            media_data = []
            
            posts = profile.get_posts()
            for post in islice(posts, 25):
                media_data.append({
                    "id": post.shortcode,
                    "caption": post.caption if post.caption else "",
                    "media_type": "VIDEO" if post.is_video else "IMAGE",
                    "media_url": post.url,
                    "thumbnail_url": post.url,
                    "permalink": f"https://www.instagram.com/p/{post.shortcode}/",
                    "timestamp": post.date_utc.isoformat() if post.date_utc else None,
                    "like_count": post.likes,
                    "comments_count": post.comments
                })
            
            print(f"[DEBUG] Extracted {len(media_data)} recent posts for '{normalized_username}'.")
            return {
                "profile_data": profile_data,
                "media_data": media_data
            }
        except instaloader.exceptions.ProfileNotExistsException as e:
            print(f"[ERROR] Instaloader raised ProfileNotExistsException for '{normalized_username}': {str(e)}")
            # Often, Instagram returns 404 or blocks the request if unauthenticated, leading to this error.
            raise ValueError(f"ProfileNotExistsException: Could not load profile '{normalized_username}'. Instagram may be blocking the unauthenticated request or the username is truly invalid. Original error: {str(e)}")
        except instaloader.exceptions.ConnectionException as e:
            print(f"[ERROR] Instaloader raised ConnectionException for '{normalized_username}': {str(e)}")
            raise ValueError(f"ConnectionException: Failed to connect to Instagram. Original error: {str(e)}")
        except Exception as e:
            print(f"[ERROR] Instaloader raised unexpected exception for '{normalized_username}': {type(e).__name__} - {str(e)}")
            raise ValueError(f"Failed to scrape profile: {type(e).__name__} - {str(e)}")

    def analyze_public_profile(self, profile_data: Dict[str, Any], stats: Dict[str, Any], username: str) -> Dict[str, Any]:
        """
        Uses Groq AI to generate a comprehensive 18-point profile analysis.
        """
        if not self.client:
            raise ValueError("GROQ_API_KEY is not configured.")

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
