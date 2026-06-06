"""
Instaloader Session Login Script
Run this once to create and save an authenticated Instagram session.
Usage: python create_session.py <instagram_username>
"""
import sys
import os
import instaloader

def main():
    if len(sys.argv) < 2:
        print("Usage: python create_session.py <instagram_username>")
        sys.exit(1)

    username = sys.argv[1].strip().lstrip('@')
    
    L = instaloader.Instaloader(
        download_pictures=False,
        download_video_thumbnails=False,
        download_videos=False,
        download_geotags=False,
        download_comments=False,
        save_metadata=False,
        compress_json=False,
    )

    print(f"[INFO] Logging in as '{username}'...")
    print("[INFO] You will be prompted for your password.")
    print("[INFO] If 2FA is enabled, you will also be prompted for the code.")

    try:
        L.login(username, input(f"Password for {username}: "))
    except instaloader.exceptions.TwoFactorAuthRequiredException:
        code = input("Enter 2FA code: ")
        L.two_factor_login(code)
    except instaloader.exceptions.BadCredentialsException:
        print("[ERROR] Invalid username or password.")
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] Login failed: {e}")
        sys.exit(1)

    # Save session
    session_dir = os.path.join(os.path.expanduser("~"), "AppData", "Local", "Instaloader")
    os.makedirs(session_dir, exist_ok=True)
    session_file = os.path.join(session_dir, f"session-{username}")
    L.save_session_to_file(session_file)
    
    print(f"[SUCCESS] Session saved to: {session_file}")
    print("[INFO] The backend will automatically load this session on startup.")

    # Quick verification
    try:
        profile = instaloader.Profile.from_username(L.context, "nasa")
        print(f"[VERIFY] Successfully fetched @nasa - Followers: {profile.followers}")
    except Exception as e:
        print(f"[VERIFY WARNING] Could not verify with @nasa: {e}")

if __name__ == "__main__":
    main()
