# -*- coding: utf-8 -*-
# test_token_quota_chat_hypothesis.py

from google import genai
from google.genai import types as genai_types
from google.genai import errors as genai_errors
import os
import time
import random

# --- Configuration ---
API_KEY = "AIzaSyBEqLhKBuknNsGa54nZNg3SdYj5Hs6zrbk" # Your API Key
MODEL_NAME = "gemini-2.5-flash-preview-05-20"    # Your Model

# Target token counts (approximate)
TARGET_TOKENS_MSG1 = 230000 # Slightly less than 240k to leave some room
TARGET_TOKENS_MSG3 = 180000  # Slightly more than 11k

# Quota we are testing against
TOKENS_PER_MINUTE_QUOTA_LIMIT = 250000

print("Initializing Gemini Client...")
client = genai.Client(api_key=API_KEY)
print(f"Gemini client initialized. Model: {MODEL_NAME}")
print(f"Testing against per-minute input token quota: {TOKENS_PER_MINUTE_QUOTA_LIMIT}")

def generate_long_string_approx_tokens(target_tokens):
    """Generates a long string of 'abc ' aiming for a target token count."""
    # Heuristic: 'abc ' is 4 chars. Let's assume roughly 1 token per 3-4 chars for simple repeating text.
    # So, target_chars = target_tokens * 3.5 (average)
    # Number of 'abc ' repetitions = target_chars / 4
    target_chars = int(target_tokens * 3.0) # Lower multiplier for safety for 'abc '
    repetitions = target_chars // 4
    long_str = ("abc " * repetitions).strip()
    print(f"Generated string of approx {len(long_str)} chars for target {target_tokens} tokens.")
    return long_str

def count_tokens_for_parts(message_parts_list, current_history_list=None):
    """Counts tokens for a list of message parts, optionally with history."""
    contents_to_count = []
    if current_history_list:
        contents_to_count.extend(current_history_list)
    if message_parts_list: # This is list[Part]
        contents_to_count.append(genai_types.Content(role="user", parts=message_parts_list))
    if not contents_to_count: return 0
    try:
        return client.models.count_tokens(model=MODEL_NAME, contents=contents_to_count).total_tokens
    except Exception as e:
        print(f"Token count error: {e}"); return -1

def get_history_list(chat_session_obj):
    try: return chat_session_obj.history
    except AttributeError: return chat_session_obj.get_history()

# --- Test Execution ---
if __name__ == "__main__":
    chat_session = None
    try:
        # 1. Create Chat Session
        chat_session = client.chats.create(model=MODEL_NAME)
        print("Chat session created.")

        # 2. Prepare and Send Message 1 (approx 240k tokens)
        print("\n--- Preparing Message 1 (User) ---")
        msg1_text_content = generate_long_string_approx_tokens(TARGET_TOKENS_MSG1)
        msg1_parts = [genai_types.Part.from_text(text=msg1_text_content)]
        
        # Verify token count for Message 1 (payload will be just this message)
        tokens_msg1_payload = count_tokens_for_parts(msg1_parts)
        print(f"Calculated tokens for Message 1 payload: {tokens_msg1_payload}")

        if tokens_msg1_payload > TOKENS_PER_MINUTE_QUOTA_LIMIT:
            print(f"ERROR: Message 1 ({tokens_msg1_payload} tokens) itself exceeds quota ({TOKENS_PER_MINUTE_QUOTA_LIMIT}). Test cannot proceed as intended.")
            exit()
        
        print("Sending Message 1 to LLM...")
        start_time_msg1 = time.time()
        response1 = chat_session.send_message(msg1_parts) # No safety_settings
        end_time_msg1 = time.time()
        print(f"Message 1 sent. LLM responded in {end_time_msg1 - start_time_msg1:.2f}s.")
        print(f"LLM Response to Message 1 (snippet): {response1.text[:100]}...")
        
        # Token count of history after Message 1 and LLM's response
        history_after_msg1 = get_history_list(chat_session)
        tokens_history_after_msg1 = count_tokens_for_parts(None, history_after_msg1)
        print(f"Total tokens in history after Message 1 + LLM response: {tokens_history_after_msg1}")
        
        # Brief pause, but keep it within the minute if possible
        # time.sleep(5) 

        # 3. Prepare and Send Message 3 (User - approx 11k tokens)
        # This message, when combined with history, should push total payload over the quota.
        print("\n--- Preparing Message 3 (User) ---")
        msg3_text_content = generate_long_string_approx_tokens(TARGET_TOKENS_MSG3)
        # Add a simple instruction to ensure it's a bit different
        msg3_text_content = "Please acknowledge this short message. " + msg3_text_content
        msg3_parts = [genai_types.Part.from_text(text=msg3_text_content)]

        # Calculate token count for the payload of Message 3 (history + msg3_parts)
        tokens_msg3_payload = count_tokens_for_parts(msg3_parts, history_after_msg1)
        print(f"Calculated tokens for Message 3 payload (history + new message): {tokens_msg3_payload}")

        if tokens_msg3_payload <= TOKENS_PER_MINUTE_QUOTA_LIMIT:
            print(f"WARNING: Message 3 payload ({tokens_msg3_payload}) is NOT expected to exceed quota. "
                  f"Test might not show the intended rate limit. "
                  f"This could be due to a short LLM response to Message 1, or tokenization differences.")
        else:
            print(f"INFO: Message 3 payload ({tokens_msg3_payload}) IS expected to exceed quota ({TOKENS_PER_MINUTE_QUOTA_LIMIT}).")


        print("Sending Message 3 to LLM...")
        start_time_msg3 = time.time()
        response3 = chat_session.send_message(msg3_parts)
        end_time_msg3 = time.time()
        print(f"Message 3 sent. LLM responded in {end_time_msg3 - start_time_msg3:.2f}s.")
        print(f"LLM Response to Message 3 (snippet): {response3.text[:100]}...")
        print("\nTEST SCENARIO: If Message 3 went through without a 429 error, "
              "it might mean the per-minute quota is more lenient for sequential calls in a chat, "
              "or the effective window reset, or the actual token count of the first LLM response was very small.")

    except genai_errors.APIError as e:
        print(f"\n--- TEST RESULT: APIError Caught ---")
        print(f"Error Message: {e.message}")
        # Check if it's a quota error
        is_quota_error = False
        if hasattr(e, 'message') and ("quota" in e.message.lower() or "resource_exhausted" in e.message.lower() or "429" in e.message.lower()):
            is_quota_error = True
        
        if is_quota_error:
            print("This appears to be a QUOTA EXHAUSTED error, as expected if total payload exceeded limits.")
            if hasattr(e, 'error_details'): # Often named 'error' or similar in the raw JSON
                 print(f"Error Details (if available): {getattr(e, 'error_details', 'N/A')}")

        else:
            print("This was an APIError but might not be quota related.")
        print("This error occurred while trying to send either Message 1 or Message 3.")
        import traceback
        traceback.print_exc()

    except Exception as e:
        print(f"\n--- TEST RESULT: UNEXPECTED Error Caught ---")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

    finally:
        print("\nTest finished.")
        if chat_session:
            final_history = get_history_list(chat_session)
            if final_history:
                tokens_final_history = count_tokens_for_parts(None, final_history)
                print(f"Total tokens in final chat history: {tokens_final_history}")
            else:
                print("Final chat history is empty or inaccessible.")