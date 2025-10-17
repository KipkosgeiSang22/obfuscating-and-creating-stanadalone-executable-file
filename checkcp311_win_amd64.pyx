import asyncio
import aiohttp
import pandas as pd
import re
import json
from datetime import datetime
import pytz

copyright = "© 2025 Joshua"

ENCODED_AUTH_STRING = 'UmVwb3J0Ok1QZHVzVHJQajFtRWFUUUV5YUtwdzlQUDZHTXJONA=='
AUTH = f'Basic {ENCODED_AUTH_STRING}'

HEADERS = {
    'Authorization': AUTH,
    'X-Requested-By': 'export-script',
    'Accept': 'application/json'
}

MAX_ROWS = 500
MAX_SHEET_NAME_LENGTH = 31

REQUIRED_FIELDS = [
    "msg", "user_name", "timestamp", "utmaction", "src_country", 
    "SubjectUserName", "IpAddress", "user", "IP", "IPV4",
    "User", "ClientAddress",
    "AccountName", "TargetUserName",
    "username", "ImagePath", "ServiceName", "ParentImage",
    "OriginalFileName", "ParentUser", "Image", "src_ip",
    "PasswordLastSet", "Timestamp", "AccountName", "AccountExpires", "dst_ip",
    "url", "destination_host_name", "destination_host_ip"
]

def sanitize_value(value):
    """Recursively sanitizes a value, list, or dictionary."""
    if isinstance(value, dict):
        return {k: sanitize_value(v) for k, v in value.items()}
    elif isinstance(value, list):
        return [sanitize_value(v) for v in value]
    elif isinstance(value, str):
        cleaned_str = re.sub(r'[\x00-\x1F]', '', value)  # Remove control characters
        cleaned_str = re.sub(r'[^\x00-\x7F]+', '', cleaned_str)  # Remove non-ASCII characters
        return cleaned_str
    else:
        return value

def convert_utc_to_local(utc_timestamp, local_tz_str='Africa/Nairobi'):
    """Convert UTC timestamp to local timezone and format it."""
    try:
        utc_time = datetime.fromisoformat(utc_timestamp.replace("Z", "+00:00"))
        local_tz = pytz.timezone(local_tz_str)
        local_time = utc_time.astimezone(local_tz)
        return local_time.strftime('%Y-%m-%d %H:%M:%S')
    except Exception as e:
        print(f"Error converting timestamp: {e}")
        return utc_timestamp  # Return original if there's an error

def sanitize_sheet_title(title):
    """Remove invalid characters from the sheet title."""
    return re.sub(r'[<>:"/\\|?*]', '', title)[:MAX_SHEET_NAME_LENGTH]

async def fetch_inputs(session, base_url):
    """Fetch inputs from the API."""
    async with session.get(f"{base_url}/api/system/inputs", headers=HEADERS, timeout=20) as response:
        response.raise_for_status()
        return await response.json()

async def fetch_search(session, base_url, input_id):
    """Fetch messages for the specific input ID."""
    async with session.get(
        f"{base_url}/api/search/universal/relative",
        params={"query": f"gl2_source_input:{input_id}", "range": 86400, "limit": 5, "fields": "*"},  # Last 24 hours and last 5 logs
        headers=HEADERS,
        timeout=20
    ) as response:
        response.raise_for_status()
        return await response.json()

async def process_client(client_name, data):
    """Process each client and export data to Excel."""
    print(f"Processing client: {client_name}")
    base_url = data['base_url']
    
    async with aiohttp.ClientSession() as session:
        inputs = await fetch_inputs(session, base_url)
        print("Inputs response:", inputs)

        with pd.ExcelWriter(f"{client_name}.xlsx", engine='openpyxl') as writer:
            for input_item in inputs.get('inputs', []):
                input_id = input_item.get('id')
                input_title = input_item.get('title', f"Input_{input_id}")  # Default title if not provided

                print(f"Fetching last message for input: {input_title}")
                print(f"Querying for input_id: {input_id}")

                try:
                    search = await fetch_search(session, base_url, input_id)
                    messages_raw = search.get("messages", [])

                    if not messages_raw:
                        print(f"No messages found for input '{input_title}'.")
                        empty_df = pd.DataFrame({"Message": [f"No last log found for '{input_title}'."]})
                        empty_df.to_excel(writer, sheet_name=sanitize_sheet_title(input_title), index=False)
                        continue

                    messages = []
                    for msg_item in messages_raw:
                        message_data = msg_item.get("message", {})
                        if 'timestamp' in message_data:
                            message_data['timestamp'] = convert_utc_to_local(message_data['timestamp'])
                        sanitized_message = sanitize_value(message_data)

                        filtered_message = {field: sanitized_message.get(field) for field in REQUIRED_FIELDS if field in sanitized_message}

                        if filtered_message:
                            messages.append(filtered_message)

                    df = pd.DataFrame(messages)

                    if not df.empty:
                        df.to_excel(writer, sheet_name=sanitize_sheet_title(input_title), index=False)
                    else:
                        empty_df = pd.DataFrame({"Message": [f"No last log found for '{input_title}'."]})
                        empty_df.to_excel(writer, sheet_name=sanitize_sheet_title(input_title), index=False)

                except Exception as e:
                    print(f"Failed to fetch last message for input '{input_title}': {e}")

async def main():
    with open('clients.json', 'r') as f:
        clients_data = json.load(f)

    tasks = [process_client(client_name, data) for client_name, data in clients_data.items()]
    await asyncio.gather(*tasks)

def run():
    asyncio.run(main())