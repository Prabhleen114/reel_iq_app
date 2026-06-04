import os
import json
from typing import List, Dict, Any, Optional

# Try importing Groq
try:
    from groq import Groq
    HAS_GROQ = True
except ImportError:
    HAS_GROQ = False

class AIService:
    def __init__(self):
        self.api_key = os.environ.get("GROQ_API_KEY", "").strip()
        self.client = None
        
        if not HAS_GROQ:
            print("ReelIQ Info: Groq package is not installed. Using local analysis pipeline.")
        elif not self.api_key:
            print("ReelIQ Info: GROQ_API_KEY environment variable is not set. Using local analysis pipeline by default.")
        else:
            try:
                self.client = Groq(api_key=self.api_key)
                print("ReelIQ Info: Groq AI service initialized successfully.")
            except Exception as e:
                print(f"ReelIQ Warning: Failed to initialize Groq client: {e}. Falling back to local analysis.")

    def analyze_reel(
        self,
        duration: float,
        scene_changes: int,
        caption: str,
        transcript: str,
        frames_metadata: List[Dict[str, Any]],
        title: str
    ) -> Dict[str, Any]:
        """
        Runs the AI analysis pipeline. Falls back to local heuristics if Groq is unavailable.
        """
        # Clean up text inputs
        combined_text = f"Title: {title}\nCaption: {caption}\nTranscript: {transcript}".strip()
        
        if self.client:
            try:
                print("ReelIQ: Groq API key found. Querying Groq Llama3 for enhanced insights...")
                return self._analyze_with_groq(duration, scene_changes, combined_text, frames_metadata)
            except Exception as e:
                print(f"ReelIQ Warning: Groq API call failed: {e}. Falling back to local analysis.")
        
        print("ReelIQ: Using local heuristics engine for offline analysis.")
        return self._analyze_locally(duration, scene_changes, caption, transcript, frames_metadata, title)

    def _analyze_with_groq(
        self,
        duration: float,
        scene_changes: int,
        combined_text: str,
        frames_metadata: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Uses Groq Free Tier (Llama3-8b-8192) to perform structured video analysis.
        """
        # Format the system prompt for structured JSON output
        system_prompt = (
            "You are ReelIQ, an expert AI creator advisor. Analyze the given Instagram Reel video metadata and text content.\n"
            "You must return a raw JSON object and nothing else. The JSON object must match this schema:\n"
            "{\n"
            '  "hook_score": int (50-100),\n'
            '  "cta_score": int (50-100),\n'
            '  "viral_score": int (50-100),\n'
            '  "engagement_score": int (50-100),\n'
            '  "caption_score": int (50-100),\n'
            '  "trend_score": int (50-100),\n'
            '  "strengths": [string],\n'
            '  "weaknesses": [string],\n'
            '  "improvements": [string],\n'
            '  "suggested_hooks": [{"type": "Curiosity"|"Problem-Solving"|"Bold Statement", "text": "string"}],\n'
            '  "suggested_ctas": [{"type": "Comment-Trigger"|"Save-Trigger"|"Share-Trigger", "text": "string"}],\n'
            '  "suggested_captions": [{"type": "Value-Packed"|"Short & Punchy"|"Storytelling", "text": "string"}]\n'
            "}"
        )

        user_prompt = (
            f"Video Metadata:\n"
            f"- Duration: {duration:.2f} seconds\n"
            f"- Scene Changes: {scene_changes} edits\n"
            f"- Extracted Visual Frame Samples Count: {len(frames_metadata)}\n\n"
            f"Text content:\n"
            f"{combined_text}\n\n"
            f"Generate realistic scoring based on pacing (shot length of 2-3s is optimal), script structure (hook first sentence, CTA at end), and keyword relevance."
        )

        chat_completion = self.client.chat.completions.create(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            model="llama3-8b-8192",
            temperature=0.3,
            response_format={"type": "json_object"}
        )

        result_text = chat_completion.choices[0].message.content
        return json.loads(result_text)

    def _analyze_locally(
        self,
        duration: float,
        scene_changes: int,
        caption: str,
        transcript: str,
        frames_metadata: List[Dict[str, Any]],
        title: str
    ) -> Dict[str, Any]:
        """
        Run a fully offline local heuristic rule engine when Groq API key is not supplied.
        """
        caption_lower = caption.lower()
        transcript_lower = transcript.lower()
        combined_lower = f"{caption_lower} {transcript_lower}".strip()

        # 1. Hook Score calculation
        hook_score = 70
        strengths = []
        weaknesses = []
        improvements = []

        # Heuristic: Check if first 3 seconds has edits/scene changes
        early_edits = sum(1 for f in frames_metadata if f.get("timestamp_seconds", 99) <= 4.0 and f.get("is_scene_change", False))
        if early_edits >= 1:
            hook_score += 15
            strengths.append("High visual pacing hook: Detected scene edits in the first 4 seconds.")
        else:
            hook_score -= 8
            weaknesses.append("Static visual hook: The video opens with a continuous shot without pacing cuts.")
            improvements.append("Add a visual pattern interrupt or jump cut within the first 2.5 seconds to retain viewers.")

        # Heuristic: Check for linguistic hook cues at beginning of caption/transcript
        hook_keywords = ["how", "why", "stop", "one", "secret", "shortcut", "hack", "never", "this is", "revealed", "don't"]
        text_start = combined_lower[:120]
        has_text_hook = any(kw in text_start for kw in hook_keywords)
        if has_text_hook:
            hook_score += 15
            strengths.append("Compelling opening script: Uses curiosity or problem-based hook phrasing at the start.")
        else:
            hook_score -= 10
            weaknesses.append("Weak script hook: Title/caption does not open with a strong value proposition or question.")
            improvements.append("Rewrite your opening hook line to highlight a problem (e.g. 'Stop wasting hours doing X').")

        hook_score = min(max(hook_score, 50), 98)

        # 2. CTA Score calculation
        cta_score = 65
        cta_keywords = ["comment", "link", "save", "share", "follow", "👇", "roadmap", "dm me", "click"]
        has_cta = any(kw in combined_lower for kw in cta_keywords)
        if has_cta:
            cta_score += 25
            strengths.append("Clear Call-to-Action: Directs the audience to comment, save, or click a link.")
        else:
            cta_score -= 15
            weaknesses.append("Absent CTA: The script or caption does not give the viewer instructions on next steps.")
            improvements.append("Append a comment-trigger CTA (e.g., 'Comment BOOTCAMP and I will DM you the code').")
        
        cta_score = min(max(cta_score, 50), 99)

        # 3. Caption Quality Score
        caption_score = 75
        hashtag_count = caption.count('#')
        if 3 <= hashtag_count <= 8:
            caption_score += 15
            strengths.append(f"Optimal hashtag count: Uses {hashtag_count} tags, which aids algorithm categorization without looking cluttered.")
        elif hashtag_count > 12:
            caption_score -= 10
            weaknesses.append(f"Excessive hashtags: Detected {hashtag_count} tags. This can trigger spam-filters or look messy.")
            improvements.append("Reduce total hashtags to 5 highly relevant terms matching your target niche.")
        else:
            improvements.append("Add 3-5 niche hashtags (e.g., #productivity, #softwareengineer) to categorize your content.")

        caption_score = min(max(caption_score, 55), 98)

        # 4. Trend Score & Engagement Score
        trend_score = 70
        trending_terms = ["ai", "chatgpt", "coding", "developer", "vscode", "minimalism", "productivity", "automation", "tech setup"]
        trend_hits = sum(1 for term in trending_terms if term in combined_lower)
        trend_score += (trend_hits * 8)
        trend_score = min(max(trend_score, 60), 96)

        # Engagement score based on pacing / shot duration
        avg_shot_length = duration / (scene_changes + 1) if scene_changes > 0 else duration
        engagement_score = 75
        if 1.8 <= avg_shot_length <= 3.8:
            engagement_score += 15
            strengths.append(f"Excellent editing rhythm: Average shot duration is {avg_shot_length:.1f}s, keeping pacing dynamic.")
        elif avg_shot_length > 6.0:
            engagement_score -= 12
            weaknesses.append(f"Slow visual rhythm: Average shot duration is {avg_shot_length:.1f}s, which can cause drop-offs.")
            improvements.append("Trim silent pauses and use dynamic b-roll overlays to keep average shot length under 4 seconds.")

        engagement_score = min(max(engagement_score, 50), 98)

        # 5. Viral Score calculation (Weighted average of metrics)
        viral_score = int(
            (hook_score * 0.35) +
            (cta_score * 0.25) +
            (engagement_score * 0.20) +
            (trend_score * 0.10) +
            (caption_score * 0.10)
        )
        viral_score = min(max(viral_score, 50), 99)

        # Clean list duplicates while preserving order
        unique_strengths = []
        for s in strengths:
            if s not in unique_strengths:
                unique_strengths.append(s)

        unique_weaknesses = []
        for w in weaknesses:
            if w not in unique_weaknesses:
                unique_weaknesses.append(w)

        unique_improvements = []
        for imp in improvements:
            if imp not in unique_improvements:
                unique_improvements.append(imp)

        # Default fallback suggestions if lists are empty
        if not unique_strengths:
            unique_strengths.append("Cohesive text messaging: Script aligns directly with caption title theme.")
        if not unique_weaknesses:
            unique_weaknesses.append("Average audio quality check: Pacing feels standard but could benefit from sound cues.")
        if not unique_improvements:
            unique_improvements.append("Test adding screen text captions at the top center to increase readability.")

        # Generate offline structured suggestions
        topic = title.strip() if title.strip() else "your topic"
        
        suggested_hooks = [
            {
                "type": "Curiosity", 
                "text": f"The secret behind {topic} that nobody tells you... 👇"
            },
            {
                "type": "Problem-Solving", 
                "text": f"Stop doing X! Here is how to master {topic} instead."
            },
            {
                "type": "Bold Statement", 
                "text": f"One simple change to double your results with {topic}."
            }
        ]

        suggested_ctas = [
            {
                "type": "Comment-Trigger", 
                "text": f"Comment '{topic.split()[0].upper() if len(topic.split()) > 0 else 'REEL'}' below and I'll DM you the free guide! 📥"
            },
            {
                "type": "Save-Trigger", 
                "text": "Save this reel for your next project so you don't lose it! 💾"
            },
            {
                "type": "Share-Trigger", 
                "text": f"Share this with a friend who needs to improve their {topic}! 🚀"
            }
        ]

        suggested_captions = [
            {
                "type": "Value-Packed", 
                "text": f"Quick guide on {topic}: \n\n1️⃣ Keep it simple\n2️⃣ Iterate fast\n3️⃣ Hook early\n\nWhat do you think? 👇 #developer #coding"
            },
            {
                "type": "Short & Punchy", 
                "text": f"If you are struggling with {topic}, try this simple adjustment. Save this for later! #productivity #minimalism"
            },
            {
                "type": "Storytelling", 
                "text": f"The easiest shortcut to {topic}: just start. It took me years to realize this, but consistency always wins. Follow for more daily dev updates. #codinglife #tech"
            }
        ]

        return {
            "hook_score": hook_score,
            "cta_score": cta_score,
            "viral_score": viral_score,
            "engagement_score": engagement_score,
            "caption_score": caption_score,
            "trend_score": trend_score,
            "strengths": unique_strengths,
            "weaknesses": unique_weaknesses,
            "improvements": unique_improvements,
            "suggested_hooks": suggested_hooks,
            "suggested_ctas": suggested_ctas,
            "suggested_captions": suggested_captions
        }

    def generate_content_calendar(
        self,
        niche: str,
        audience: str,
        goal: str,
        frequency: str
    ) -> Dict[str, Any]:
        """
        Generates a 30-day content calendar. Falls back to local templates if Groq is offline or not configured.
        """
        if self.client:
            try:
                print(f"ReelIQ: Generating content calendar for niche '{niche}' using Groq...")
                return self._generate_calendar_with_groq(niche, audience, goal, frequency)
            except Exception as e:
                print(f"ReelIQ Warning: Groq calendar generation failed: {e}. Falling back to local templates.")
        
        print("ReelIQ: Using local calendar generation engine.")
        return self._generate_calendar_locally(niche, audience, goal, frequency)

    def _generate_calendar_with_groq(
        self,
        niche: str,
        audience: str,
        goal: str,
        frequency: str
    ) -> Dict[str, Any]:
        system_prompt = (
            "You are ReelIQ, an expert AI content strategist. Generate a customized 30-day content calendar for Instagram Reels.\n"
            "You must return a raw JSON object and nothing else. The JSON object must match this schema:\n"
            "{\n"
            '  "niche": "string",\n'
            '  "audience": "string",\n'
            '  "goal": "string",\n'
            '  "frequency": "string",\n'
            '  "days": [\n'
            '    {\n'
            '      "day": int (1-30),\n'
            '      "title": "string (short topic)",\n'
            '      "idea": "string (Daily Reel Idea)",\n'
            '      "hook": "string (Suggested Hook)",\n'
            '      "caption": "string (Suggested Caption)",\n'
            '      "cta": "string (Suggested CTA)",\n'
            '      "posting_time": "string (Recommended Posting Time, e.g. 6:00 PM)",\n'
            '      "difficulty": "Easy"|"Medium"|"Hard"\n'
            '    }\n'
            '  ]\n'
            "}"
        )
        
        user_prompt = (
            f"Please generate a 30-day calendar for a creator in the '{niche}' niche.\n"
            f"- Target Audience: {audience}\n"
            f"- Goal: {goal}\n"
            f"- Posting Frequency: {frequency}\n"
            f"Tailor each day to be highly relevant to the niche, target audience, and goal. Ensure diverse hooks, CTAs, and captions."
        )

        chat_completion = self.client.chat.completions.create(
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            model="llama3-8b-8192",
            temperature=0.4,
            response_format={"type": "json_object"}
        )

        result_text = chat_completion.choices[0].message.content
        return json.loads(result_text)

    def _generate_calendar_locally(
        self,
        niche: str,
        audience: str,
        goal: str,
        frequency: str
    ) -> Dict[str, Any]:
        # Local template generation
        days = []
        
        # 30 day template components
        ideas = [
            ("Top 3 Mistakes in {niche}", "Sharing the most common mistakes {audience} make and how to fix them.", "Easy"),
            ("How to reach {goal} fast", "A quick step-by-step workflow customized for {audience}.", "Medium"),
            ("My favorite tool for {niche}", "Highlighting a specific tool that helps {audience} automate or simplify.", "Easy"),
            ("Busting a common {niche} myth", "Debunking a widespread belief to capture attention and build authority.", "Medium"),
            ("Before vs After {goal}", "A visual representation showing the transformation of {audience}.", "Hard"),
            ("1 simple tip for {niche}", "An actionable bite-sized advice that anyone can try today.", "Easy"),
            ("The secret behind {niche} success", "A breakdown of what successful creators in this niche do differently.", "Medium"),
            ("Stop doing this in {niche}", "An audit style reel pointing out inefficient habits.", "Easy"),
            ("Tutorial: Master {niche} in 60s", "A fast-paced step-by-step masterclass style guide.", "Hard"),
            ("A day in the life of a {niche} creator", "A behind-the-scenes look to build personal connection with {audience}.", "Medium"),
            ("3 hacks to double your {niche} results", "Quick productivity tips to get better outcomes.", "Easy"),
            ("How I started with {niche}", "Your personal backstory or origin story to foster trust.", "Medium"),
            ("The biggest lesson I learned in {niche}", "A reflective piece sharing a key breakthrough moment.", "Medium"),
            ("Why {audience} fail at {niche}", "A bold analysis of typical pitfalls and obstacles.", "Easy"),
            ("An alternative approach to {goal}", "Showing a contrarian view on how to get results.", "Hard"),
            ("Quick checklist for {niche}", "A bullet-point breakdown of essentials.", "Easy"),
            ("Common question: answered", "Addressing the #1 question {audience} ask about {niche}.", "Easy"),
            ("Reviewing {niche} trends", "Your opinion on a current hot topic or trend in the space.", "Medium"),
            ("Avoid this {niche} trap", "A cautionary tale or warning about a common mistake.", "Medium"),
            ("The future of {niche} in 2026", "A futuristic prediction that creates discussion.", "Hard"),
            ("If I had to start over in {niche}", "A 3-step action plan if starting from absolute scratch.", "Medium"),
            ("X vs Y: Which is better for {goal}?", "A direct comparison of two popular methods or tools.", "Easy"),
            ("This 1 habit changed my {niche} game", "Sharing a daily routine that leads to success.", "Easy"),
            ("Behind the scenes: {niche} setup", "Showcasing the workspace, software, or tools used.", "Medium"),
            ("How to automate your {niche} workflow", "Saving time with automation tools and scripts.", "Hard"),
            ("3 resources for {niche} beginners", "Recommending books, websites, or accounts to follow.", "Easy"),
            ("A contrarian opinion on {niche}", "Sharing an unpopular opinion to provoke comments.", "Medium"),
            ("Case study: Achieving {goal}", "Deconstructing a specific success story.", "Hard"),
            ("My top recommendation for {audience}", "A heartfelt advice or suggestion.", "Easy"),
            ("30-day review: Let's reflect", "Summarizing the journey and asking the audience for feedback.", "Medium")
        ]

        times = ["8:30 AM", "12:00 PM", "3:00 PM", "6:00 PM", "7:30 PM", "9:00 PM"]
        
        for i in range(30):
            day_num = i + 1
            idx = i % len(ideas)
            title_tpl, desc_tpl, diff = ideas[idx]
            
            day_title = title_tpl.format(niche=niche, audience=audience, goal=goal)
            day_idea = desc_tpl.format(niche=niche, audience=audience, goal=goal)
            
            day_hook = f"Stop scrolling if you want to achieve {goal} with {niche}! 🚨" if i % 2 == 0 else f"Here is the secret about {niche} they don't want you to know... 👇"
            day_caption = f"If you are a part of {audience} and your goal is to master {niche}, this daily tip is for you!\n\nHere is what you need to do:\n1️⃣ Understand the fundamentals\n2️⃣ Practice daily\n3️⃣ Learn from mistakes\n\nSave this reel for later!"
            day_cta = f"Comment '{niche.split()[0].upper() if len(niche.split()) > 0 else 'REEL'}' for a free resource! 📥" if i % 2 == 0 else "Follow for more daily tips! 🚀"
            posting_time = times[i % len(times)]
            
            days.append({
                "day": day_num,
                "title": day_title,
                "idea": day_idea,
                "hook": day_hook,
                "caption": day_caption,
                "cta": day_cta,
                "posting_time": posting_time,
                "difficulty": diff
            })
            
        return {
            "niche": niche,
            "audience": audience,
            "goal": goal,
            "frequency": frequency,
            "days": days
        }
