"""
Minimal diagnostic test for Instaloader scraping.
Pinpoints the exact failure point in scrape_public_profile().
"""
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')
import os
import glob
import traceback
import instaloader
from instaloader import Profile

print("=" * 70)
print("REELIQ INSTALOADER DIAGNOSTIC TEST")
print("=" * 70)

# ── Step 1: Print Instaloader version ──
print(f"\n[1] Instaloader version: {instaloader.__version__}")
print(f"    Python version: {sys.version}")

# ── Step 2: Initialize Instaloader ──
print("\n[2] Initializing Instaloader instance...")
L = instaloader.Instaloader(
    download_pictures=False,
    download_video_thumbnails=False,
    download_videos=False,
    download_geotags=False,
    download_comments=False,
    save_metadata=False,
    compress_json=False,
)
print("    ✓ Instaloader initialized")

# ── Step 3: Load session ──
print("\n[3] Loading session...")
session_dir = os.path.join(os.path.expanduser("~"), "AppData", "Local", "Instaloader")
session_file = None
session_username = None

if os.path.isdir(session_dir):
    matches = glob.glob(os.path.join(session_dir, "session-*"))
    if matches:
        session_file = matches[0]
        session_username = os.path.basename(session_file).replace("session-", "")

if session_file:
    try:
        L.load_session_from_file(session_username, session_file)
        print(f"    ✓ Session loaded for @{session_username}")
        print(f"    ✓ Session file: {session_file}")
    except Exception as e:
        print(f"    ✗ Session load FAILED: {e}")
        traceback.print_exc()
else:
    print(f"    ✗ No session file found in {session_dir}")

# ── Step 4: Test Profile.from_username ──
test_username = sys.argv[1] if len(sys.argv) > 1 else "nasa"
print(f"\n[4] Testing Profile.from_username('{test_username}')...")
try:
    profile = Profile.from_username(L.context, test_username)
    print(f"    ✓ Profile loaded successfully!")
    print(f"    ✓ Username: {profile.username}")
    print(f"    ✓ Full name: {profile.full_name}")
    print(f"    ✓ Followers: {profile.followers}")
    print(f"    ✓ Following: {profile.followees}")
    print(f"    ✓ Posts: {profile.mediacount}")
    print(f"    ✓ Is private: {profile.is_private}")
    print(f"    ✓ Biography: {profile.biography[:80]}...")
except Exception as e:
    print(f"    ✗ Profile.from_username FAILED: {type(e).__name__}: {e}")
    traceback.print_exc()
    print("\n[RESULT] Failure at PROFILE FETCH stage. The GraphQL query for profile")
    print("         metadata itself is broken. This is an Instaloader version issue.")
    sys.exit(1)

# ── Step 5: Test get_posts() iterator creation ──
print(f"\n[5] Testing profile.get_posts() iterator creation...")
try:
    posts_iterator = profile.get_posts()
    print(f"    ✓ Posts iterator created (lazy, no request yet)")
except Exception as e:
    print(f"    ✗ get_posts() FAILED: {type(e).__name__}: {e}")
    traceback.print_exc()
    sys.exit(1)

# ── Step 6: Test fetching first post ──
print(f"\n[6] Testing fetching FIRST post (this triggers the GraphQL query)...")
try:
    first_post = next(iter(posts_iterator))
    print(f"    ✓ First post fetched!")
    print(f"    ✓ Shortcode: {first_post.shortcode}")
    print(f"    ✓ Date: {first_post.date_utc}")
    print(f"    ✓ Is video: {first_post.is_video}")
except StopIteration:
    print(f"    ⚠ No posts found (empty iterator)")
except Exception as e:
    print(f"    ✗ FIRST POST FETCH FAILED: {type(e).__name__}: {e}")
    traceback.print_exc()
    print("\n[RESULT] Failure at POSTS ITERATION stage.")
    print("         The profile loads fine but get_posts() GraphQL query fails.")
    print("         This is the QueryReturnedBadRequestException - Instaloader sends")
    print("         an outdated GraphQL query hash that Instagram no longer accepts.")
    sys.exit(1)

# ── Step 7: Test accessing post details ──
print(f"\n[7] Testing post detail access (likes, comments, caption)...")
try:
    print(f"    ✓ Likes: {first_post.likes}")
    print(f"    ✓ Comments: {first_post.comments}")
    caption = first_post.caption if first_post.caption else "(no caption)"
    print(f"    ✓ Caption: {caption[:80]}...")
    print(f"    ✓ URL: {first_post.url}")
except Exception as e:
    print(f"    ✗ Post detail access FAILED: {type(e).__name__}: {e}")
    traceback.print_exc()
    sys.exit(1)

# ── Step 8: Test fetching a few more posts ──
print(f"\n[8] Testing fetching 3 more posts...")
try:
    post_count = 1  # already have 1
    posts_iterator2 = profile.get_posts()
    for i, post in enumerate(posts_iterator2):
        if i >= 4:
            break
        post_count = i + 1
        print(f"    ✓ Post {i+1}: {post.shortcode} | Likes: {post.likes} | Video: {post.is_video}")
    print(f"    ✓ Successfully fetched {post_count} posts")
except Exception as e:
    print(f"    ✗ Multi-post fetch FAILED at post {post_count + 1}: {type(e).__name__}: {e}")
    traceback.print_exc()
    sys.exit(1)

print("\n" + "=" * 70)
print("ALL TESTS PASSED - Scraping pipeline is functional")
print("=" * 70)
